import { Application } from '@yowasp/runtime';
import { instantiate } from '../gen/boolector.js';

export { Exit } from '@yowasp/runtime';

const boolector = new Application(() => import('./resources-boolector.js'), instantiate, 'yowasp-boolector');
const runBoolector = boolector.run.bind(boolector);

export { runBoolector };
export const commands = { 'boolector': runBoolector };
