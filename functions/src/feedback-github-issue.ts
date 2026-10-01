import * as functions from 'firebase-functions';

/**
 * app_common_kit: フィードバック（バグ報告・改善要望）の GitHub Issue 自動化
 *
 * 各アプリの Firestore `feedback` コレクション（app_common_kit の
 * FeedbackNotifier.setSubmitHandler で書き込まれる想定）への onCreate を検知し、
 * GitHub Issues API を呼び出して Issue を自動作成する「半自動化」の仕組み。
 *
 * アプリごとに Issue を作成する GitHub リポジトリが異なるため、デプロイ時に
 * 環境変数 GITHUB_OWNER / GITHUB_REPO をアプリに合わせて設定すること。
 * GITHUB_TOKEN は Secret として設定する（対象リポジトリの
 * "Issues: Read and write" 権限のみを持つ fine-grained PAT を推奨）。
 *
 * デプロイ手順は README.md を参照。
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
      console.error(
        'GITHUB_OWNER / GITHUB_REPO / GITHUB_TOKEN が未設定のため Issue 化をスキップしました'
      );
      return;
    }

    const typeLabelMap: Record<string, string> = {
      bug: 'bug',
      feature: 'enhancement',
      other: 'feedback',
    };
    const label = typeLabelMap[report.type as string] ?? 'feedback';

    const title = `[${report.appName ?? 'unknown'}] ${report.title ?? '(無題)'}`;
    const body = [
      report.description ?? '',
      '',
      '---',
      `種別: ${report.type ?? 'unknown'}`,
      `プラットフォーム: ${report.platform ?? 'unknown'}`,
      `アプリバージョン: ${report.appVersion ?? ''}`,
      `報告日時: ${report.createdAt ?? ''}`,
      report.userId ? `userId: ${report.userId}` : null,
    ]
      .filter((line): line is string => line !== null)
      .join('\n');

    try {
      const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/issues`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: JSON.stringify({ title, body, labels: [label] }),
      });

      if (!res.ok) {
        const text = await res.text();
        throw new Error(`GitHub API error: ${res.status} ${text}`);
      }

      const issue = (await res.json()) as { html_url: string };
      await snap.ref.update({
        githubIssueUrl: issue.html_url,
        status: 'reviewing',
      });
    } catch (error) {
      console.error('Error creating GitHub issue from feedback:', error);
    }
  });
