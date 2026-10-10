import * as functions from 'firebase-functions';
import { buildIssue, duplicateComment, fingerprint, fingerprintMarker } from './feedback-issue';

/**
 * app_common_kit: フィードバック（バグ報告・改善要望）の GitHub Issue 自動化
 *
 * 各アプリの Firestore `feedback` コレクション（app_common_kit の
 * FeedbackNotifier.setSubmitHandler で書き込まれる想定）への onCreate を検知し、
 * GitHub Issues API で Issue を作成する。
 *
 * - 同じ内容（アプリ・種別・題名が同じ）の報告は、新しい Issue を作らず既存の Issue にコメントする
 * - Issue には種別ラベル（bug / enhancement / feedback）とアプリ名ラベル（app:<名前>）を付ける
 * - 修正用の `autofix` ラベルは、ここでは付けない（利用者が書いた文章を、そのまま自動修正に
 *   流さないため。内容を確認した人が手で付ける）
 *
 * デプロイ時に環境変数 GITHUB_OWNER / GITHUB_REPO、Secret の GITHUB_TOKEN
 * （対象リポジトリの "Issues: Read and write" のみを持つ fine-grained PAT）を設定する。
 * 手順は README.md を参照。
 */
export const onFeedbackCreated = functions.firestore
  .document('feedback/{feedbackId}')
  .onCreate(async (snap) => {
    const report = snap.data();
    if (!report) return;

    const owner = process.env.GITHUB_OWNER;
    const repo = process.env.GITHUB_REPO;
    const token = process.env.GITHUB_TOKEN;
    if (!owner || !repo || !token) {
      console.error('GITHUB_OWNER / GITHUB_REPO / GITHUB_TOKEN が未設定のため Issue 化をスキップしました');
      return;
    }

    const headers = {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
    const api = `https://api.github.com/repos/${owner}/${repo}`;

    try {
      // 1. 同じ指紋の、開いている Issue を探す
      const fp = fingerprint(report);
      const q = encodeURIComponent(`repo:${owner}/${repo} is:issue is:open in:body "${fingerprintMarker(fp)}"`);
      const found = await fetch(`https://api.github.com/search/issues?q=${q}&per_page=1`, { headers });
      if (found.ok) {
        const data = (await found.json()) as { items?: { number: number; html_url: string; comments: number }[] };
        const existing = data.items?.[0];
        if (existing) {
          const count = existing.comments + 2; // 最初の報告 + これまでの重複 + 今回
          const res = await fetch(`${api}/issues/${existing.number}/comments`, {
            method: 'POST',
            headers,
            body: JSON.stringify({ body: duplicateComment(report, count) }),
          });
          if (!res.ok) throw new Error(`GitHub API error: ${res.status} ${await res.text()}`);
          await snap.ref.update({ githubIssueUrl: existing.html_url, status: 'reviewing', duplicate: true });
          return;
        }
      }

      // 2. 無ければ新しい Issue を作る
      const draft = buildIssue(report);
      const res = await fetch(`${api}/issues`, { method: 'POST', headers, body: JSON.stringify(draft) });
      if (!res.ok) throw new Error(`GitHub API error: ${res.status} ${await res.text()}`);
      const issue = (await res.json()) as { html_url: string };
      await snap.ref.update({ githubIssueUrl: issue.html_url, status: 'reviewing' });
    } catch (error) {
      console.error('Error creating GitHub issue from feedback:', error);
    }
  });
