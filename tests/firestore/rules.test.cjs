const {before, after, beforeEach, test} = require('node:test');
const {readFileSync} = require('node:fs');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp} = require('firebase/firestore');
let env;
const post = {userId:'owner', userName:'Owner', content:'Hello', likes:0, dislikes:0, comments:0, likedBy:[], dislikedBy:[]};
const comment = {userId:'alice', userName:'Alice', content:'Hello', photoUrl:'', createdAt:serverTimestamp()};
const notification = (type='like', commentId='none') => ({actorId:'alice',postId:'p',commentId,type,isRead:false,createdAt:serverTimestamp(),title:'New reaction',body:'A reaction'});
const db = (uid='alice') => env.authenticatedContext(uid).firestore();
before(async () => {
  env = await initializeTestEnvironment({projectId:'demo-skincare-rules',firestore:{host:'127.0.0.1',port:8085,rules:readFileSync('../../firestore.rules','utf8')}});
});
after(async () => {if (env) await env.cleanup();});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(),'posts/p'),post);
    await setDoc(doc(c.firestore(),'users/owner'),{uid:'owner'});
  });
});
test('owner reads profile; others and guests cannot', async () => {
  await assertSucceeds(getDoc(doc(db('owner'),'users/owner')));
  await assertFails(getDoc(doc(db(),'users/owner')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'posts/p')));
});
test('only own reaction may change, with exact counts', async () => {
  const ref=doc(db(),'posts/p');
  await assertFails(updateDoc(ref,{likes:99}));
  await assertFails(updateDoc(ref,{likes:1,likedBy:['bob']}));
  await assertSucceeds(updateDoc(ref,{likes:1,likedBy:['alice']}));
  await assertFails(updateDoc(ref,{dislikes:1,dislikedBy:['alice']}));
  await assertSucceeds(updateDoc(ref,{likes:0,likedBy:[],dislikes:1,dislikedBy:['alice']}));
  await assertFails(updateDoc(doc(db('bob'),'posts/p'),{dislikes:0,dislikedBy:[]}));
});
test('like notification requires matching atomic reaction; cannot spoof or spam', async () => {
  const d=db(); const n=doc(d,'users/owner/notifications/like_p_alice');
  await assertFails(setDoc(n,notification()));
  const batch=writeBatch(d);
  batch.update(doc(d,'posts/p'),{likes:1,likedBy:['alice']});
  batch.set(doc(d,'posts/p/likeReceipts/alice'),{createdAt:serverTimestamp()});
  batch.set(n,notification());
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(doc(d,'users/owner/notifications/random'),notification()));
  await assertFails(updateDoc(n,{body:'Forged'}));
  await assertSucceeds(updateDoc(doc(db('owner'),'users/owner/notifications/like_p_alice'),{isRead:true}));
  await assertFails(updateDoc(doc(db('owner'),'users/owner/notifications/like_p_alice'),{body:'Changed'}));
});
test('comment creation and deletion require matching counter in same commit', async () => {
  const d=db(); const p=doc(d,'posts/p'); const c=doc(d,'posts/p/comments/c');
  await assertFails(setDoc(c,comment));
  await assertFails(updateDoc(p,{comments:1,lastCommentId:'c'}));
  const batch=writeBatch(d);
  batch.set(c,comment);
  batch.update(p,{comments:1,lastCommentId:'c'});
  batch.set(doc(d,'users/owner/notifications/comment_c'),notification('comment','c'));
  await assertSucceeds(batch.commit());
  await assertFails(deleteDoc(c));
  const stranger=db('bob');
  const foreign=writeBatch(stranger);
  foreign.delete(doc(stranger,'posts/p/comments/c'));
  foreign.update(doc(stranger,'posts/p'),{comments:0,lastCommentId:'c'});
  await assertFails(foreign.commit());
  const remove=writeBatch(d); remove.delete(c); remove.update(p,{comments:0,lastCommentId:'c'});
  await assertSucceeds(remove.commit());
});
test('cannot add two comments against a single counter increment', async () => {
  const d=db(); const batch=writeBatch(d);
  batch.set(doc(d,'posts/p/comments/c'),comment);
  batch.set(doc(d,'posts/p/comments/d'),comment);
  batch.update(doc(d,'posts/p'),{comments:1,lastCommentId:'c'});
  await assertFails(batch.commit());
});
test('private collections can be cleaned only by their owner', async () => {
  await env.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(),'users/owner/wardrobe/item'),{name:'Item'});
  });
  await assertFails(deleteDoc(doc(db(),'users/owner/wardrobe/item')));
  await assertSucceeds(deleteDoc(doc(db('owner'),'users/owner/wardrobe/item')));
});
