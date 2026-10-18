import {API_KEY, authRequest, passwordError, errorMessage} from './auth-api.js';
const $ = id => document.getElementById(id);
const params = new URLSearchParams(location.search);
let code = params.get('oobCode');
const mode = params.get('mode');
// Do not retain the single-use code in browser history or pass it to other sites.
history.replaceState(null, '', location.pathname);
let busy = false;
let timer;
function screen(title, description, content, icon = '↗') {
  $('title').textContent = title;
  $('description').textContent = description;
  $('state-icon').textContent = icon;
  for (const id of ['loading', 'password-form', 'request-form', 'retry', 'success', 'other-action']) $(id).hidden = id !== content;
}
function error(id, message) { $(id).textContent = message; $(id).hidden = !message; }
function requestScreen(message) {
  screen('Một liên kết mới nhé?', message, 'request-form', '✉');
}
async function verify() {
  if (busy) return;
  if (code && ['verifyEmail', 'recoverEmail', 'verifyAndChangeEmail', 'revertSecondFactorAddition'].includes(mode)) {
    const target = new URL('https://myapp-7f561.firebaseapp.com/__/auth/action');
    target.search = new URLSearchParams({mode, oobCode: code, apiKey: API_KEY, lang: 'vi'});
    $('other-action').href = target.href;
    screen('Xác minh tài khoản', 'Tiếp tục với trang xác minh Firebase để hoàn tất yêu cầu tài khoản của bạn.', 'other-action');
    return;
  }
  if (!code || mode !== 'resetPassword') {
    requestScreen(mode && mode !== 'resetPassword'
      ? 'Đây không phải liên kết đặt lại mật khẩu. Bạn có thể xin liên kết đúng bên dưới.'
      : 'Nhập email tài khoản để nhận liên kết đặt lại mật khẩu từ Skincare.');
    return;
  }
  busy = true;
  screen('Đang kiểm tra liên kết', 'Chờ một chút nhé, tụi mình đang chuẩn bị trang đặt lại mật khẩu cho bạn.', 'loading');
  try {
    const data = await authRequest('resetPassword', {oobCode: code});
    screen('Đặt lại mật khẩu', `Tạo mật khẩu mới cho ${data.email}. Sau đó bạn có thể quay lại hành trình chăm da.`, 'password-form');
  } catch (e) {
    if (['EXPIRED_OOB_CODE','INVALID_OOB_CODE','USER_DISABLED','EMAIL_NOT_FOUND'].includes(e.code)) {
      code = null;
      requestScreen(errorMessage(e));
    } else screen('Kết nối đang gián đoạn', errorMessage(e), 'retry');
  } finally { busy = false; }
}
$('retry').addEventListener('click', verify);
document.querySelectorAll('.reveal').forEach(button => button.addEventListener('click', () => {
  const field = $(button.dataset.for);
  field.type = field.type === 'password' ? 'text' : 'password';
  button.textContent = field.type === 'password' ? 'Hiện' : 'Ẩn';
  button.setAttribute('aria-label', `${field.type === 'password' ? 'Hiện' : 'Ẩn'} mật khẩu`);
  button.setAttribute('aria-pressed', String(field.type === 'text'));
}));
$('password-form').addEventListener('submit', async event => {
  event.preventDefault();
  if (busy || !code) return;
  const message = passwordError($('password').value, $('confirm').value);
  error('password-error', message);
  if (message) return;
  busy = true; $('save').disabled = true; $('save').textContent = 'Đang lưu mật khẩu…';
  try {
    await authRequest('resetPassword', {oobCode: code, newPassword: $('password').value});
    code = null;
    $('password-form').reset();
    screen('Mật khẩu đã được đổi!', 'Tài khoản của bạn đã sẵn sàng. Chào mừng bạn trở lại với Skincare.', 'success', '✓');
  } catch (e) {
    if (['EXPIRED_OOB_CODE','INVALID_OOB_CODE'].includes(e.code)) {
      code = null; requestScreen(errorMessage(e));
    } else error('password-error', errorMessage(e));
  } finally { busy = false; $('save').disabled = false; $('save').textContent = 'Lưu mật khẩu mới →'; }
});
$('request-form').addEventListener('submit', async event => {
  event.preventDefault();
  if (busy || $('send').disabled) return;
  busy = true; $('send').disabled = true; error('request-error', '');
  $('send').textContent = 'Đang gửi liên kết…';
  let sent = false;
  try {
    await authRequest('sendOobCode', {requestType: 'PASSWORD_RESET', email: $('email').value.trim()});
    sent = true;
  } catch (e) {
    if (e.code === 'EMAIL_NOT_FOUND') sent = true;
    else error('request-error', errorMessage(e));
  } finally { busy = false; }
  if (sent) {
    $('title').textContent = 'Kiểm tra hộp thư nhé';
    $('description').textContent = 'Nếu email này đủ điều kiện, bạn sẽ nhận được liên kết mới. Mở email mới nhất để tiếp tục đặt lại mật khẩu.';
    let seconds = 60;
    $('send').textContent = `Gửi lại sau ${seconds}s`;
    clearInterval(timer);
    timer = setInterval(() => {
      seconds--;
      $('send').textContent = seconds ? `Gửi lại sau ${seconds}s` : 'Gửi liên kết mới →';
      if (!seconds) {clearInterval(timer); $('send').disabled = false;}
    }, 1000);
  } else { $('send').disabled = false; $('send').textContent = 'Gửi liên kết mới →'; }
});
window.addEventListener('pagehide', () => clearInterval(timer));
verify();
