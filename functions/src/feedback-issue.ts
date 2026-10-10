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
}

const TYPE_LABEL: Record<string, string> = {
  bug: 'bug',
  feature: 'enhancement',
  other: 'feedback',
};

export const MAX_BODY = 4000;

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
