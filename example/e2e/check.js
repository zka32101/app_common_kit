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
    home: ['今日から始めよう', '合計', 'もう一度試す'],
    feedback: ['ご意見・不具合報告', '不具合報告', '改善要望', '送信する'],
    wardrobe: ['着替え・ショップ', '合格したときに解放されます', '学習コイン'],
    menuButton: '推しのメニュー',
    menuItems: ['推しを選ぶ', '試験の結果を報告'],
    correct: '正解',
    incorrect: '不正解',
  },
  en: {
    home: ['Start today', 'Total', 'Try again'],
    feedback: ['Feedback & bug reports', 'Bug report', 'Feature request', 'Send'],
    wardrobe: ['Outfits & shop', 'Unlocked when you pass', 'Study coins'],
    menuButton: 'Companion menu',
    menuItems: ['Choose companion', 'Report exam result'],
    correct: 'Correct',
    incorrect: 'Incorrect',
  },
};

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined, args: ['--no-sandbox'] });
  const page = await browser.newPage({
    // 言語を明示する。headless shell は言語情報が空で、Flutter が起動時に落ちるため。
    locale: 'ja-JP',
    viewport: { width: 420, height: 1000 },
  });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));

  const text = async () => (await page.locator('flt-semantics').allInnerTexts()).join('\n');
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

    // 着替え・ショップ
    await click('button', 'Open wardrobe');
    for (const s of t.wardrobe) check(`[${lang}] 着替えに「${s}」`, await waitText(s));
    await page.screenshot({ path: `${shots}/${lang}-wardrobe.png` });
    await back();

    // 片手モード: 不正解の選択肢を押すと、押した方が不正解・正解の方が正解と出る
    await click('button', 'Open hands-free');
    check(`[${lang}] 片手モードの問題文`, await waitText('1 + 1'));
    await click('button', '3'); // B の選択肢（不正解）
    check(`[${lang}] 片手モードで「${t.incorrect}」`, await waitText(t.incorrect));
    check(`[${lang}] 片手モードで「${t.correct}」`, await waitText(t.correct));
    await page.screenshot({ path: `${shots}/${lang}-handsfree.png` });
    await back();

    // 推しカードのメニュー → 着替え・ショップ（カードの文言が積んだ画面に引き継がれる）
    await click('button', t.menuButton);
    for (const s of t.menuItems) {
      check(`[${lang}] 推しメニューに「${s}」`, (await page.getByRole('menuitem', { name: s }).count()) > 0);
    }
    await click('menuitem', t.wardrobe[0]);
    check(`[${lang}] 推しメニューから着替え画面（「${t.wardrobe[0]}」）`, await waitText(t.wardrobe[1]));
    await page.screenshot({ path: `${shots}/${lang}-oshi-wardrobe.png` });
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
