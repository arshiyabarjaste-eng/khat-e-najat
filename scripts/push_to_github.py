#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
push_to_github.py
--------------------------------------------------------------------------------
این اسکریپت مخزن «خط نجات» را به گیت‌هاب شما پوش می‌کند.

استفاده:
    python3 push_to_github.py <github_token> <github_username> [repo_name]

مثال:
    python3 push_to_github.py ghp_xxx YourUsername khat-e-najat

پیش‌نیازها:
    pip install requests

نکته امنیتی: توکن خود را با کسی به اشتراک نگذارید و پس از استفاده
از حساب Settings → Developer settings → Personal access tokens آن را
باطل کنید یا حداقل دامنه‌اش را محدود کنید.
"""

import subprocess
import sys
import os
import json
import urllib.request
import urllib.error


def run(cmd, check=True, capture=False):
    """اجرای فرمان shell."""
    print(f"→ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=capture, text=True)
    if check and result.returncode != 0:
        if capture:
            print(result.stdout)
            print(result.stderr, file=sys.stderr)
        sys.exit(1)
    return result


def create_repo(token, username, repo_name, description):
    """ساخت مخزن در گیت‌هاب با REST API."""
    url = "https://api.github.com/user/repos"
    data = json.dumps({
        "name": repo_name,
        "description": description,
        "private": False,  # عمومی؛ برای خصوصی True کنید
        "has_issues": True,
        "has_wiki": True,
        "auto_init": False,
    }).encode("utf-8")

    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"token {token}")
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            return body.get("html_url"), body.get("clone_url")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"❌ HTTP {e.code}: {err_body}", file=sys.stderr)
        if e.code == 422:
            print("   (مخزن با این نام از قبل وجود دارد. ادامه با پوش...)", file=sys.stderr)
            return None, None
        sys.exit(1)


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    token = sys.argv[1]
    username = sys.argv[2]
    repo_name = sys.argv[3] if len(sys.argv) > 3 else "khat-e-najat"

    description = "خط نجات | Khat-e Nejat — بازی موبایلی دوبعدی معمایی مبتنی بر رسم خطوط با هویت ایرانی (Godot 4.3)"

    print(f"\n📁 ساخت مخزن {repo_name} در حساب {username}...")
    html_url, clone_url = create_repo(token, username, repo_name, description)

    if clone_url is None:
        clone_url = f"https://github.com/{username}/{repo_name}.git"
    else:
        print(f"✅ مخزن ساخته شد: {html_url}")

    # Configure remote
    print("\n🔧 پیکربندی remote...")
    run(f'git remote remove origin', check=False)
    run(f'git remote add origin {clone_url}')

    # Push
    print("\n🚀 پوش به گیت‌هاب...")
    # Embed token in URL for HTTPS auth (so we don't need ssh keys)
    authed_url = clone_url.replace("https://", f"https://{username}:{token}@")
    run(f'git remote set-url origin {authed_url}')
    push_result = run(f'git push -u origin main', check=False, capture=True)
    print(push_result.stdout)
    if push_result.returncode != 0:
        print(push_result.stderr, file=sys.stderr)
        # Fall back to pushing to master if main fails
        print("\n🔄 تلاش با شاخه master...")
        run(f'git branch -M master')
        run(f'git push -u origin master', check=False)

    # Reset URL to remove token from config (security)
    run(f'git remote set-url origin {clone_url}')
    print("\n✅ تمام!")
    print(f"\n📦 مخزن شما: {html_url or 'https://github.com/' + username + '/' + repo_name}")
    print("📥 برای کلون:")
    print(f"   git clone {clone_url}")


if __name__ == "__main__":
    main()
