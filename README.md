# aws-vpn-client

_Forked from https://github.com/samm-git/aws-vpn-client_

## Usage

1. Clone this repository
2. Download the openvpn client configuration from the self-service portal
3. Copy it into the root of this repo, renaming it to `vpn.conf`
4. Run `docker-compose up --build`
5. Follow the link to sign in with SSO
    ```
    aws-vpn-client | Open this URL in your browser and log in (ctrl + click):
    aws-vpn-client | https://...........
    ```
6. Sign in if you do not already have an active session
7. You should see the VPN connected successfully with the final log line as below. If you don't, try again, it's a bit flaky
    ```
    aws-vpn-client | 2021-04-30 13:33:37 Initialization Sequence Completed
    ```