# Design: Rate Limiting with Exponential Backoff (Iteration 80+)

## Problem
Telegraph, Gemini, and Telegram APIs can return HTTP 429 (rate limiting)
or transient errors (5xx, timeouts). Current code fails immediately.

## Solution
1. Create Tgph::HTTP module with retry logic
2. Replace HTTP::Tiny->new with Tgph::HTTP in:
   - Tgph::Publish::send_requests
   - Yt2tg::Gemini::send_request
   - Yt2tg::Telegram::send_message/sendPhoto
3. CLI options: --retry-count N, --retry-delay SECONDS
4. Exponential backoff: delay * 2^attempt (1s, 2s, 4s, 8s...)

## Tgph::HTTP API

    my $http = Tgph::HTTP->new(
        timeout      => 30,
        retry_count  => 3,
        retry_delay  => 1,
        agent        => 'tgph/0.0.1',
    );

    my $response = $http->request('POST', $url, {
        content => $form_data,
    });

    # Returns same structure as HTTP::Tiny response
    # Retries on: 429, 5xx, timeouts, connection errors

## Retry logic

- Retryable status codes: 429, 500, 502, 503, 504
- Non-retryable: 4xx (except 429), success (2xx)
- Backoff formula: delay * 2^attempt
- Jitter: random 0-25% to avoid thundering herd
- Logging: warn "retrying (attempt N/M) after status S"

## CLI options

- --retry-count N (default: 3)
- --retry-delay SECONDS (default: 1)
- Propagated through all tools: pubtgph, tgph-publish, tgph-edit, yt2tg

## Implementation phases

### Phase 1 (Iteration 80): Tgph::HTTP module
- Create bin/lib/Tgph/HTTP.pm with retry logic
- Unit tests for retry behavior
- Integration with Tgph::Publish

### Phase 2 (Iteration 81+): Yt2tg modules
- Replace HTTP::Tiny in Yt2tg::Gemini
- Replace HTTP::Tiny in Yt2tg::Telegram
- CLI option propagation

### Phase 3 (future): testing
- Mock HTTP 429 responses
- Verify exponential backoff timing
