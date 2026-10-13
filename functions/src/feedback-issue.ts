import { createHash } from 'crypto';

/** Firestore の `feedback` ドキュメント（FeedbackReport.toJson()）のうち、Issue 化に使う項目。 */
export interface FeedbackDoc {
  type?: string;
  title?: string;
  description?: string;
  appName?: string;
  appVersion?: string;
  platform?: string;
  createdAt?: string;
  userId?: string;
  /** 診断情報（版・端末・直近の操作の記録）。利用者が添えたときだけ付く。 */
  diagnostics?: string;
}

const TYPE_LABEL: Record<string, string> = {
  bug: 'bug',
  feature: 'enhancement',
  other: 'feedback',
};

export const MAX_BODY = 4000;
export const MAX_DIAGNOSTICS = 3000;

/** 同じ内容の報告を同じ値にまとめるための指紋。アプリ・種別・題名（大小文字と空白を無視）で決まる。 */
export function fingerprint(r: FeedbackDoc): string {
  const norm = (s?: string) => (s ?? '').normalize('NFKC').toLowerCase().replace(/\s+/g, ' ').trim();
  const src = [norm(r.appName), norm(r.type), norm(r.title)].join('|');
  return createHash('sha256').update(src).digest('hex').slice(0, 16);
}

export const fingerprintMarker = (fp: string) => `<!-- feedback-fingerprint:${fp} -->`;

export interface IssueDraft {
  title: string;
  body: string;
  labels: string[];
}

/**
 * 診断情報を、折りたたみ（`<details>`）の中のコードブロックにして返す。無ければ空。
 * 利用者が書いた文字列なので、コードブロックを閉じる記号（```）と HTML のタグは無害にする。長さも切り詰める。
 */
export function diagnosticsSection(diagnostics?: string): string[] {
  const text = (diagnostics ?? '').trim();
  if (!text) return [];
  const safe = text
    .slice(0, MAX_DIAGNOSTICS)
    .replace(/`/g, "'")
    .replace(/</g, '＜')
    .replace(/>/g, '＞');
  return ['', '<details><summary>診断情報</summary>', '', '```', safe, '```', '', '</details>'];
}

/** Issue の題名・本文・ラベルを組み立てる。アプリ名のラベル（`app:<名前>`）で絞り込める。 */
export function buildIssue(r: FeedbackDoc): IssueDraft {
  const app = r.appName?.trim() || 'unknown';
  const labels = [TYPE_LABEL[r.type ?? ''] ?? 'feedback', `app:${app}`];
  const desc = (r.description ?? '').slice(0, MAX_BODY);
  const body = [
    desc,
    '',
    '---',
    '| 項目 | 内容 |',
    '|---|---|',
    `| アプリ | ${app} |`,
    `| バージョン | ${r.appVersion ?? ''} |`,
    `| プラットフォーム | ${r.platform ?? 'unknown'} |`,
    `| 種別 | ${r.type ?? 'unknown'} |`,
    `| 報告日時 | ${r.createdAt ?? ''} |`,
    r.userId ? `| userId | ${r.userId} |` : null,
    ...diagnosticsSection(r.diagnostics),
    '',
    fingerprintMarker(fingerprint(r)),
  ]
    .filter((l): l is string => l !== null)
    .join('\n');
  return { title: `[${app}] ${r.title?.trim() || '(無題)'}`, body, labels };
}

/** 重複報告に付けるコメント（同じ報告が何件目か、どの環境か）。 */
export function duplicateComment(r: FeedbackDoc, count: number): string {
  return [
    `同じ内容の報告が届きました（${count}件目）。`,
    `- バージョン: ${r.appVersion ?? ''} / プラットフォーム: ${r.platform ?? 'unknown'} / 日時: ${r.createdAt ?? ''}`,
    '',
    r.description ? `> ${r.description.slice(0, 500).replace(/\n/g, '\n> ')}` : '',
  ].join('\n');
}
