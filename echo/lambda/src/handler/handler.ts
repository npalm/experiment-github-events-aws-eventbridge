import { Webhooks } from '@octokit/webhooks';
import { Schema } from '@octokit/webhooks-types';
import { IncomingHttpHeaders } from 'http';

import { LogFields, logger as rootLogger } from './logger';

const logger = rootLogger.getChildLogger();

export async function handle(event: Schema): Promise<void> {
  logger.info('Handling event: ' + JSON.stringify(event));
}
