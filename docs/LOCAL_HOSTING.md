# One shared local city

The current phone playtest runs at **http://100.89.1.14:4173** on this machine's Tailscale address. Connect Tailscale on the phone, then open that address in its normal browser. The same server also listens at http://127.0.0.1:4173 for desktop QA.

Both addresses use **one SQLite city**, with shared markets, events, projects, contributions, and neural messages. Each browser gets a signed, HttpOnly local session cookie and its own character. Use the same address and browser to return to that character; another browser or device starts a different character. These local characters are separate from the hosted Sites database.

The database is `.local-data/city.sqlite`; the session signing key is `.local-data/session.key`. Both are ignored by Git. Neither a rebuild nor server restart resets them. Local migrations apply once and preserve existing data. Keep the data directory when updating source. Clearing a browser's cookie loses that browser's access to its existing local character.

## Run manually

Requires Node 22.20 or newer.

```sh
npm ci
npm run build
npm run dev
```

To also listen on the current machine's Tailscale interface:

```sh
SCHISM_TAILSCALE_IP=100.89.1.14 npm run dev
```

The server binds only loopback and the explicitly supplied Tailscale IP. It does not bind all LAN interfaces. Local sessions belong to this development adapter; the deployed Worker continues to require trusted Sites identity.

## This machine's persistent service

`schism-local.service` is enabled in the user's systemd manager. Its working directory is `/home/commander/ashfall`, its Node binary is `/home/commander/.local/node-runtime/bin/node`, and it sets `SCHISM_TAILSCALE_IP=100.89.1.14`. It restarts after a process failure and uses the existing ignored data directory.

```sh
systemctl --user status schism-local.service
systemctl --user restart schism-local.service
journalctl --user -u schism-local.service -n 40
```

Rebuild before restarting after source changes. Leave this service running for the owner's phone playtesting. Do not start a second server on the same port. The service file lives at `/home/commander/.config/systemd/user/schism-local.service`; it is machine configuration outside the repository.

## Repeat the browser playthrough

The optional browser check creates two normal test citizens in this shared city, spends their real energy, posts a test message, and waits for actual short-task deadlines. It checks all 16 screens at 360px, 390px, and 1440px, plus crafting during work, contract effects, and appearance persistence. It takes several minutes and leaves those ordinary citizens in the city.

```sh
SCHISM_QA_URL=http://100.89.1.14:4173 npm run test:browser
```

Set `SCHISM_BROWSER` to a Chromium-family browser executable when `/opt/brave-bin/brave` is unavailable. Screenshots default to ignored `.local-data/qa-screenshots`; `SCHISM_QA_OUTPUT` can override that directory. Unit tests inject server time in isolated in-memory databases and do not touch phone characters.

For v0.7's encounters, free planning, emergency response, and funded supply-order flow, run the **20-minute** shared-city check:

```sh
SCHISM_QA_URL=http://100.89.1.14:4173 npm run test:district-browser
```

It registers two normal mobile citizens, starts a real fifteen-minute custodial shift, waits through actual short-task/reply deadlines, and uses the earned wages to fund an order filled by the other citizen. It checks all screens at 360/390/1440px and writes pacing samples plus screenshots to ignored `.local-data/district-playtest`. It leaves both characters in the same city and does not grant resources or accelerate timestamps. Private storage-state files in that directory permit returning to those QA characters; do not commit or publish their cookies. Changing `SCHISM_QA_OUTPUT` also changes this evidence directory. A crisis response is only exercised when the current live deadline allows it; isolated rule checks cover other phases.

For a bounded portrait review, run `npm run test:portraits` against the existing Tailscale service. It uses the saved Iona Vex session at `.local-data/qa-browser.json`, renders 135 face/build/hair/outfit combinations and six color pairs, checks 360/390/1440px profiles, and previews shaved/braided mobile intake without submitting registration. It does not post gameplay actions or change saved appearance/equipment. `SCHISM_QA_SESSION` can select another private Playwright storage-state file for an existing registered local citizen; its cookies must belong to `SCHISM_QA_URL`. Outputs default to ignored `.local-data/portrait-review`. Inspect the generated images as well as the automation result: rendering checks alone cannot establish anatomical correctness.


For v0.8's free housing, automatic reserve, remembered Neri continuation, shared building chat/shelf, and six completed repairs, run:

```sh
SCHISM_QA_URL=http://100.89.1.14:4173 npm run test:living-browser
```

It creates two ordinary mobile arrivals, gathers project supplies through real bin tasks, contributes six real thirty-second repairs during fifteen-minute custodial shifts, receives actual wages, and transfers a ration through the shelf. The default evidence directory is ignored `.local-data/living-playtest`; private saved sessions permit returning to the same characters. It checks all 17 screens at 360/390/1440px. Its random bin rolls can leave inadequate project stock within the available quota; that is a genuine supply constraint, not permission to grant supplies. Keep a failed run's characters; inspect state before resuming. After all six repairs, `SCHISM_QA_REUSE=1 SCHISM_QA_STAGE=finish` skips gathering and repair setup while retaining current wages and resources. `SCHISM_QA_REUSE=1` restores its saved sessions for an interrupted intake/gathering run, and does not rewind completed work.

`npm run test:balance` uses isolated in-memory SQLite and injected server time for seven-day visit schedules. It never accesses the phone city, and writes a public numeric report under `docs/playtests/v0.8/`. Simulated multi-day deadlines do not replace human multi-day pacing assessment.
