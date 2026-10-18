import {test} from 'node:test';
import assert from 'node:assert/strict';
import {authRequest, passwordError, errorMessage, AuthError} from '../auth-api.js';
test('validates confirmation without altering password whitespace', () => {
  assert.notEqual(passwordError('123', '123'), '');
  assert.notEqual(passwordError('abcdef', 'abcdeg'), '');
  assert.equal(passwordError(' abcdef ', ' abcdef '), '');
});
test('checks action code without submitting a new password', async () => {
  await authRequest('resetPassword', {oobCode: 'test-code'}, {fetcher: async (url, init) => {
    assert.equal(new URL(url).hostname, 'identitytoolkit.googleapis.com');
    assert.deepEqual(JSON.parse(init.body), {oobCode:'test-code'});
    assert.equal(init.referrerPolicy,'no-referrer');
    return {ok:true,json:async()=>({email:'test@example.com'})};
  }});
});
test('expired code has actionable error', async () => {
  await assert.rejects(authRequest('resetPassword', {}, {fetcher:async()=>({ok:false,json:async()=>({error:{message:'EXPIRED_OOB_CODE'}})})}), e => {
    assert.match(errorMessage(e),/liên kết mới/); return true;
  });
});
test('network failures have a readable message', async () => {
  await assert.rejects(authRequest('resetPassword', {}, {fetcher:async()=>{throw new TypeError('private detail');}}), e => {
    assert.equal(e.code,'NETWORK'); assert.doesNotMatch(errorMessage(e),/private/); return true;
  });
});
test('request times out instead of loading forever', async () => {
  await assert.rejects(authRequest('resetPassword', {}, {timeout:5,fetcher:(_, {signal}) => new Promise((resolve,reject) => signal.addEventListener('abort',()=>reject(new DOMException('aborted','AbortError'))))}), e => e.code === 'TIMEOUT');
});
test('password policy failures are readable', () => {
  assert.match(errorMessage(new AuthError('PASSWORD_DOES_NOT_MEET_REQUIREMENTS')), /Mật khẩu/);
});
