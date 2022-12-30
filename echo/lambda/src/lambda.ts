import { Schema } from '@octokit/webhooks-types';
import { Context, EventBridgeEvent } from 'aws-lambda';

import { handle } from './handler/handler';
import { logger } from './handler/logger';

export async function echo(event: EventBridgeEvent<'test', Schema>, context: Context): Promise<void> {
  logger.setSettings({ requestId: context.awsRequestId });
  logger.debug(JSON.stringify(event));

  try {
    await handle(event.detail);
  } catch (e) {
    if (e instanceof Error) {
      throw e;
    } else {
      logger.warn(`Ignoring error: ${(e as Error).message}`);
    }
  }
}
