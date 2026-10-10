// example アプリ（Flutter Web）を Playwright で操作して、日本語・英語の表示と画面遷移を確認する。
//   node check.js [スクリーンショットの保存先]
// Flutter Web は文字をキャンバスに描くので、アクセシビリティ（semantics）を有効にして文字とボタンを拾う。
const { chromium } = require('playwright');

const shots = process.argv[2] || '.';
const failures = [];

function check(name, ok) {
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${name}`);
  if (!ok) failures.push(name);
}

// 言語ごとの期待値。
const T = {
  ja: {
    settings: ['設定', '表示モード', '片手・ながら学習', 'ご意見・不具合報告'],
    settingsTheme: ['ダーク'],
    home: ['今日から始めよう', 'もう一度試す'],
    feedback: ['ご意見・不具合報告', '不具合報告', '改善要望', '送信する'],
    correct: '正解',
    incorrect: '不正解',
  },
  en: {
    settings: ['Settings', 'Appearance', 'One-handed study', 'Feedback & bug reports'],
    settingsTheme: ['Dark'],
    home: ['Start today', 'Try again'],
    feedback: ['Feedback & bug reports', 'Bug report', 'Feature request', 'Send'],
    correct: 'Correct',
    incorrect: 'Incorrect',
  },
};

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--no-sandbox'] });
  const page = await browser.newPage({
    // 言語を明示する。headless shell は言語情報が空で、Flutter が起動時に落ちるため。
    locale: 'ja-JP',
    viewport: { width: 420, height: 1400 },
  });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));

  // 文字は innerText と aria-label の両方から拾う（タブやボタンの名前は aria-label にだけ入る）。
  const text = async () =>
    page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics')]
        .map(e => `${e.innerText || ''}\n${e.getAttribute('aria-label') || ''}`)
        .join('\n'));
  const waitText = async (s, timeout = 8000) => {
    const end = Date.now() + timeout;
    while (Date.now() < end) {
      if ((await text()).includes(s)) return true;
      await page.waitForTimeout(200);
    }
    return false;
  };
  const click = async (role, name) => {
    await page.getByRole(role, { name, exact: false }).first().click({ force: true });
    await page.waitForTimeout(700);
  };
  const back = async () => click('button', 'Back');
  // 失敗の原因を追えるよう、画面の文字を出す。
  const dump = async (label) => console.log(`--- ${label} の画面の文字 ---\n${(await text()).slice(0, 1500)}\n---`);

  await page.goto('http://localhost:8099/');
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder').click());
  await page.waitForTimeout(1500);

  for (const lang of ['ja', 'en']) {
    const t = T[lang];
    if (lang === 'en') {
      await page.getByRole('switch').first().click({ force: true });
      await page.waitForTimeout(1000);
    }

    // ホーム
    for (const s of t.home) check(`[${lang}] ホームに「${s}」`, await waitText(s));
    await page.screenshot({ path: `${shots}/${lang}-home.png` });

    // フィードバック画面（積んだ画面に文言が届く）
    await click('button', 'Open feedback');
    for (const s of t.feedback) check(`[${lang}] フィードバックに「${s}」`, await waitText(s));
    await page.screenshot({ path: `${shots}/${lang}-feedback.png` });
    await back();

    // 片手モード: 不正解の選択肢を押すと、押した方が不正解・正解の方が正解と出る
    await click('button', 'Open hands-free');
    check(`[${lang}] 片手モードの問題文`, await waitText('1 + 1'));
    await click('button', '3'); // B の選択肢（不正解）
    check(`[${lang}] 片手モードで「${t.incorrect}」`, await waitText(t.incorrect));
    check(`[${lang}] 片手モードで「${t.correct}」`, await waitText(t.correct));
    await page.screenshot({ path: `${shots}/${lang}-handsfree.png` });
    await back();

    // 設定画面。積んだ画面に文言が届き、購入欄・受験日も同じ言語で出る。
    // 購入・受験日の操作（ボタン名が日本語）は ja のときだけ行う。
    await click('button', 'Open settings');
    for (const x of t.settings) check(`[${lang}] 設定に「${x}」`, await waitText(x));
    check(`[${lang}] 設定の中の受験日も同じ言語`, await waitText(lang === 'ja' ? '受験日' : 'Exam date'));
    await click('button', t.settingsTheme[0]); // 表示モードを選べる
    await page.screenshot({ path: `${shots}/${lang}-settings.png` });
    if (lang === 'ja') {
      const hasOffer = (await waitText('広告非表示')) && (await waitText('¥480'));
      check('[ja] 購入欄に商品と価格', hasOffer);
      if (!hasOffer) await dump('購入欄');
      check('[ja] 購入を復元ボタン', await waitText('購入を復元'));
      check('[ja] 受験日は未設定', await waitText('未設定'));
      await page.screenshot({ path: `${shots}/ja-settings-before.png` });

      await click('button', '¥480');
      const bought = await waitText('広告非表示を購入済みです');
      check('[ja] 購入すると購入済み表示', bought);
      if (!bought) await dump('購入後');

      // 受験日: ピッカーを開いて今日の日付のまま決定 → 日付が出る。解除で未設定に戻る。
      const today = await page.evaluate(() => {
        const d = new Date();
        return `${d.getFullYear()}/${d.getMonth() + 1}/${d.getDate()}`;
      });
      await click('button', '受験日');
      await dump('受験日ピッカー');
      await click('button', 'OK');
      const hasDate = await waitText(today);
      check(`[ja] 受験日に今日（${today}）が入る`, hasDate);
      if (!hasDate) await dump('受験日決定後');
      await page.screenshot({ path: `${shots}/ja-settings-after.png` });
      await click('button', '受験日を解除');
      check('[ja] 受験日を解除すると未設定に戻る', await waitText('未設定'));
    }
    await back();

  }

  check('ページエラーなし', errors.length === 0);
  if (errors.length) console.log(errors.join('\n'));
  await browser.close();
  if (failures.length) {
    console.log(`\n${failures.length} 件失敗`);
    process.exitCode = 1;
  }
})();
