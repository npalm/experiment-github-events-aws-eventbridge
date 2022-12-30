import { EventBridgeClient, PutEventsCommand } from '@aws-sdk/client-eventbridge';
import { Webhooks } from '@octokit/webhooks';
import { IncomingHttpHeaders } from 'http';

import { Response } from '../lambda';
import { getParameterValue } from '../ssm';
import { LogFields, logger as rootLogger } from './logger';

const logger = rootLogger.getChildLogger();

export async function handle(headers: IncomingHttpHeaders, body: string): Promise<Response> {
  const { eventBusName, eventSource } = readEnvironmentVariables();

  // ensure header keys lower case since github headers can contain capitals.
  for (const key in headers) {
    headers[key.toLowerCase()] = headers[key];
  }

  const githubEvent = (headers['x-github-event'] as string) || 'github-event-lambda';
  let response: Response = {
    statusCode: await verifySignature(githubEvent, headers, body),
  };
  if (response.statusCode != 200) return response;

  const payload = JSON.parse(body);
  LogFields.fields.event = githubEvent;
  LogFields.fields.repository = payload.repository.full_name || '';

  logger.info(`Processing Github event`, LogFields.print());
  const client = new EventBridgeClient({ region: process.env.AWS_REGION });
  const command = new PutEventsCommand({
    Entries: [
      {
        EventBusName: eventBusName,
        Source: eventSource,
        DetailType: githubEvent,
        Detail: body,
      },
    ],
  });

  try {
    const result = await client.send(command);
    response =
      result.FailedEntryCount === 0
        ? {
            statusCode: 200,
            body: 'Event sent to EventBridge successfully.',
          }
        : {
            statusCode: 500,
            body: 'Event failed to send to EventBridge.',
          };
  } catch (e) {
    logger.error(`Failed to send event to EventBridge`, LogFields.print());
    response.statusCode = 500;
    if (e instanceof Error) {
      response.body = e.message;
    } else {
      response.body = JSON.stringify(e);
    }
  }

  logger.info(`Response: ${response.statusCode}`, LogFields.print());
  return response;
}

function readEnvironmentVariables() {
  const eventBusName = process.env.EVENT_BUS_NAME;
  const eventSource = process.env.EVENT_SOURCE || 'github.com';
  return { eventBusName, eventSource };
}

async function verifySignature(githubEvent: string, headers: IncomingHttpHeaders, body: string): Promise<number> {
  let signature;
  if ('x-hub-signature-256' in headers) {
    signature = headers['x-hub-signature-256'] as string;
  } else {
    signature = headers['x-hub-signature'] as string;
  }
  if (!signature) {
    logger.error(
      "Github event doesn't have signature. This webhook requires a secret to be configured.",
      LogFields.print(),
    );
    return 500;
  }

  const secret = await getParameterValue(process.env.PARAMETER_GITHUB_APP_WEBHOOK_SECRET);

  const webhooks = new Webhooks({
    secret: secret,
  });
  if (!(await webhooks.verify(body, signature))) {
    logger.error('Unable to verify signature!', LogFields.print());
    return 401;
  }
  return 200;
}
