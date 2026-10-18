// Firebase client API key identifies this project; it is not an admin credential.
export const API_KEY = 'AIzaSyBPYC6t5iBSZ5i2HjDDjTW9PCn3wgILUHc';
const BASE = 'https://identitytoolkit.googleapis.com/v1';
export class AuthError extends Error {
  constructor(code) { super(code); this.code = code; }
}
export async function authRequest(method, body, {fetcher = fetch, base = BASE, key = API_KEY, timeout = 15000} = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout);
  try {
    const response = await fetcher(`${base}/accounts:${method}?key=${encodeURIComponent(key)}`, {
      method: 'POST', headers: {'Content-Type': 'application/json', 'X-Firebase-Locale': 'vi'},
      body: JSON.stringify(body), signal: controller.signal, credentials: 'omit', referrerPolicy: 'no-referrer',
    });
    const data = await response.json();
    if (!response.ok) throw new AuthError(data.error?.message?.split(' : ')[0] || 'UNKNOWN');
    return data;
  } catch (error) {
    if (error instanceof AuthError) throw error;
    throw new AuthError(error.name === 'AbortError' ? 'TIMEOUT' : 'NETWORK');
  } finally { clearTimeout(timer); }
}
export function passwordError(password, confirmation) {
  if (password.length < 6) return 'Mật khẩu cần ít nhất 6 ký tự.';
  if (password !== confirmation) return 'Hai mật khẩu chưa khớp. Bạn kiểm tra lại nhé.';
  return '';
}
export function errorMessage(error) {
  switch (error.code) {
    case 'EXPIRED_OOB_CODE': case 'INVALID_OOB_CODE': return 'Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới bên dưới nhé.';
    case 'WEAK_PASSWORD': case 'PASSWORD_DOES_NOT_MEET_REQUIREMENTS': return 'Mật khẩu chưa đáp ứng yêu cầu của tài khoản. Hãy thử mật khẩu dài hơn, có chữ hoa, chữ thường, số và ký tự đặc biệt.';
    case 'TOO_MANY_ATTEMPTS_TRY_LATER': case 'RESET_PASSWORD_EXCEED_LIMIT': return 'Bạn thử hơi nhiều lần rồi. Hãy đợi vài phút trước khi tiếp tục nhé.';
    case 'INVALID_EMAIL': return 'Email chưa đúng định dạng. Bạn kiểm tra lại nhé.';
    case 'TIMEOUT': return 'Kết nối phản hồi quá lâu. Kiểm tra mạng rồi thử lại nhé.';
    case 'NETWORK': return 'Chưa kết nối được. Kiểm tra mạng rồi thử lại nhé.';
    default: return 'Chưa thể hoàn tất lúc này. Vui lòng thử lại sau.';
  }
}
