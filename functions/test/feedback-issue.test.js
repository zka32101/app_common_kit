const test = require('node:test');
const assert = require('node:assert');
const { fingerprint, buildIssue, duplicateComment, diagnosticsSection, MAX_BODY, MAX_DIAGNOSTICS } = require('../lib/feedback-issue');

const base = { type: 'bug', title: 'クラッシュする', description: '開くと落ちます', appName: 'kokugo-kore', appVersion: '1.2.0', platform: 'iOS', createdAt: '2026-10-10T00:00:00Z' };

test('指紋は大小文字・空白・全角半角の違いを無視する', () => {
  const a = fingerprint({ ...base, title: 'Crash  on start', appName: 'App' });
  const b = fingerprint({ ...base, title: ' crash on START ', appName: 'app' });
  assert.strictEqual(a, b);
  assert.strictEqual(fingerprint({ ...base, title: 'ＡＢＣ' }), fingerprint({ ...base, title: 'abc' }));
});

test('アプリ・種別・題名が違えば指紋も違う', () => {
  const f = fingerprint(base);
  assert.notStrictEqual(f, fingerprint({ ...base, appName: 'other' }));
  assert.notStrictEqual(f, fingerprint({ ...base, type: 'feature' }));
  assert.notStrictEqual(f, fingerprint({ ...base, title: '別の件' }));
});

test('Issue にラベル・メタ情報・指紋が入る', () => {
  const i = buildIssue({ ...base, userId: 'u1' });
  assert.strictEqual(i.title, '[kokugo-kore] クラッシュする');
  assert.deepStrictEqual(i.labels, ['bug', 'app:kokugo-kore']);
  assert.ok(i.body.includes('| バージョン | 1.2.0 |'));
  assert.ok(i.body.includes('| userId | u1 |'));
  assert.ok(i.body.includes(`feedback-fingerprint:${fingerprint(base)}`));
  assert.ok(!i.labels.includes('autofix'));
});

test('種別ごとのラベル、未知の種別・欠けた項目でも落ちない', () => {
  assert.strictEqual(buildIssue({ ...base, type: 'feature' }).labels[0], 'enhancement');
  assert.strictEqual(buildIssue({ ...base, type: 'zzz' }).labels[0], 'feedback');
  const e = buildIssue({});
  assert.strictEqual(e.title, '[unknown] (無題)');
});

test('長すぎる本文は切る', () => {
  const i = buildIssue({ ...base, description: 'あ'.repeat(MAX_BODY + 500) });
  assert.ok(!i.body.includes('あ'.repeat(MAX_BODY + 1)));
});

test('重複コメントに件数と環境が入る', () => {
  const c = duplicateComment({ ...base, description: '1行目\n2行目' }, 3);
  assert.ok(c.includes('3件目'));
  assert.ok(c.includes('iOS'));
  assert.ok(c.includes('> 1行目\n> 2行目'));
});

test('診断情報は、折りたたみのコードブロックで本文に入る', () => {
  const i = buildIssue({ ...base, diagnostics: 'app: x\nversion: 1.2.0\n\nrecent:\n10:00:00 開いた' });
  assert.ok(i.body.includes('<details><summary>診断情報</summary>'));
  assert.ok(i.body.includes('version: 1.2.0'));
  assert.ok(i.body.includes('</details>'));
  // 指紋の印は、診断情報のあとにあっても残る（重複検知は題名等で決まり、診断情報には影響されない）
  assert.ok(i.body.includes(`feedback-fingerprint:${fingerprint(base)}`));
  assert.strictEqual(fingerprint({ ...base, diagnostics: 'a' }), fingerprint({ ...base, diagnostics: 'b' }));
});

test('診断情報が無い・空なら、本文に診断情報の欄を出さない（従来どおり）', () => {
  assert.ok(!buildIssue(base).body.includes('診断情報'));
  assert.ok(!buildIssue({ ...base, diagnostics: '   ' }).body.includes('診断情報'));
  assert.deepStrictEqual(diagnosticsSection(undefined), []);
});

test('診断情報は、コードブロックを閉じる記号と HTML を無害にし、長さを切る', () => {
  const evil = 'ok\n```\n<script>alert(1)</script>\n## 偽の見出し';
  const lines = diagnosticsSection(evil);
  const text = lines.join('\n');
  // コードブロックの開始と終了の ``` だけが残る（利用者の文字列由来の ``` は無い）
  assert.strictEqual(text.split('```').length - 1, 2);
  assert.ok(!text.includes('<script>'));
  const long = diagnosticsSection('あ'.repeat(MAX_DIAGNOSTICS + 500)).join('\n');
  assert.ok(!long.includes('あ'.repeat(MAX_DIAGNOSTICS + 1)));
});
