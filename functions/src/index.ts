import * as admin from 'firebase-admin';

admin.initializeApp();

export { onFeedbackCreated } from './feedback-github-issue';
