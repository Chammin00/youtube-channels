"""
Automated YouTube Data API v3 Dual-Uploader (Long-Form + Short + Custom Thumbnail + Session Links).
Requires: pip install google-api-python-client google-auth-oauthlib
Place your Google Cloud OAuth 2.0 Desktop client_secret.json in this folder and run:
    python youtube_api_upload.py --episode-id ep01-eustace-stupid-dog
"""
import argparse
import json
import os
import sys
from pathlib import Path


def build_long_description(
    ep: dict,
    all_episodes: list[dict],
    channel_handle: str = "@CartoonWhiteNoise",
    playlist_url: str = "",
    request_url: str = "",
) -> str:
    noise_title = ep.get("noise_color", "brown").capitalize()
    interval_mins = max(1, int(ep.get("interval_seconds", 600)) // 60)

    # Collect up to 3 previously uploaded episodes for internal binge-linking
    previous_links = []
    for other in all_episodes:
        if other.get("id") != ep.get("id") and other.get("long_video_url"):
            previous_links.append(f"• {other['character']} ({other['show']}): {other['long_video_url']}")
    previous_block = ""
    if previous_links:
        previous_block = "\n\n🎧 MORE CARTOON & GAMING WHITE NOISE:\n" + "\n".join(previous_links[:3])

    playlist_line = f"\n▶️ Full Sleep & Study Ambience Playlist: {playlist_url}" if playlist_url else ""
    request_line = f"\n⚡ Priority Character / Line Request: {request_url}" if request_url else ""

    return (
        f"{ep['long_title']} — Soothing {noise_title} Noise for sleep, studying, and ADHD focus, "
        f"interrupted by 1 iconic {ep['character']} ({ep['show']}) soundbyte: \"{ep['quote']}\"\n\n"
        f"🔔 Subscribe for more nostalgic sleep static: https://www.youtube.com/{channel_handle}?sub_confirmation=1"
        f"{playlist_line}"
        f"{previous_block}\n\n"
        f"⏱️ CHAPTERS & SOUND SCHEDULE:\n"
        f"0:00 Warm {noise_title} Noise Calibration\n"
        f"0:03 Instant Soundbyte Preview (\"{ep['quote']}\")\n"
        f"0:15 Deep {noise_title} Static Loop (Repeats Every ~{interval_mins} Mins)\n"
        f"10:00 Scheduled {ep['character']} Interruption\n"
        f"30:00 Deep REM Static & Low-Pass Ambience\n\n"
        f"💬 VOTE NEXT EPISODE:\n"
        f"Which cartoon or video game character + exact line should interrupt the static next? "
        f"Drop it in the comments — top reply gets rendered next!"
        f"{request_line}\n\n"
        f"#whitenoise #{ep.get('noise_color', 'brown')}noise #sleepambience #nostalgia #studymusic"
    )


def build_short_description(
    ep: dict,
    long_video_id: str,
    channel_handle: str = "@CartoonWhiteNoise",
    playlist_url: str = "",
) -> str:
    playlist_line = f"Full Sleep Playlist: {playlist_url}\n" if playlist_url else ""
    return (
        f"{ep['short_hook_text']}\n"
        f"🎧 Full 1-Hour Sleep Version: https://youtu.be/{long_video_id}\n"
        f"{playlist_line}"
        f"🔔 More Character White Noise: https://www.youtube.com/{channel_handle}?sub_confirmation=1\n\n"
        f"Featured Soundbyte: {ep['character']} ({ep['show']}) — \"{ep['quote']}\"\n"
        f"Drop the next character + quote you want to hear in the comments!\n\n"
        f"#shorts #whitenoise #{ep.get('noise_color', 'brown')}noise #nostalgia #sleep"
    )


def post_top_comment(youtube, video_id: str, text: str) -> None:
    try:
        youtube.commentThreads().insert(
            part="snippet",
            body={
                "snippet": {
                    "videoId": video_id,
                    "topLevelComment": {
                        "snippet": {
                            "textOriginal": text,
                        }
                    },
                }
            },
        ).execute()
        print(f"Posted engagement comment on video {video_id} (ready to Pin in YouTube Studio).")
    except Exception as exc:
        print(f"Note: Could not auto-post comment on {video_id} ({exc}). Copy-paste manually:")
        print(f"    {text}")


def upload_episode_pair(
    episode_id: str,
    client_secret_path: Path,
    privacy: str = "public",
    channel_handle: str = "@CartoonWhiteNoise",
    playlist_url: str = "",
    request_url: str = "",
):
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print("Installing required Google YouTube API packages...")
        os.system(f'"{sys.executable}" -m pip install google-api-python-client google-auth-oauthlib')
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload

    base_dir = Path(__file__).resolve().parent
    catalog_path = base_dir / "character_rotation_catalog.json"
    episodes = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
    ep = next((e for e in episodes if e["id"] == episode_id), episodes[0])

    short_video = base_dir / "output" / f"{ep['id']}_SHORT_9x16.mp4"
    long_video = base_dir / "output" / f"{ep['id']}_LONG_16x9.mp4"
    thumb_file = base_dir / "assets" / "branding" / f"{ep['id']}_thumbnail_1280x720.png"
    if not thumb_file.exists():
        thumb_file = base_dir / "assets" / "branding" / "ep01_thumbnail_1280x720.png"

    if not client_secret_path.exists():
        raise FileNotFoundError(
            f"Missing OAuth client_secret.json at {client_secret_path}. "
            "Download an OAuth 2.0 Desktop Client JSON from Google Cloud Console (YouTube Data API v3 enabled) "
            "or use the opened YouTube Studio browser window to drag-and-drop the rendered MP4 files."
        )

    scopes = [
        "https://www.googleapis.com/auth/youtube.upload",
        "https://www.googleapis.com/auth/youtube.force-ssl",
    ]
    flow = InstalledAppFlow.from_client_secrets_file(str(client_secret_path), scopes)
    credentials = flow.run_local_server(port=0)
    youtube = build("youtube", "v3", credentials=credentials)

    # 1. Upload Long-Form 16:9 Video First (so we get its Video ID to link from the Short)
    print(f"Uploading Long-Form Video: {ep['long_title']}...")
    long_description = build_long_description(
        ep=ep,
        all_episodes=episodes,
        channel_handle=channel_handle,
        playlist_url=playlist_url,
        request_url=request_url,
    )
    long_body = {
        "snippet": {
            "title": ep["long_title"],
            "description": long_description,
            "tags": [
                "white noise",
                f"{ep.get('noise_color', 'brown')} noise",
                ep["character"],
                ep["show"],
                "sleep ambience",
                "cartoon white noise",
                "study static",
            ],
            "categoryId": "24",
        },
        "status": {
            "privacyStatus": privacy,
            "selfDeclaredMadeForKids": False,
        },
    }
    long_req = youtube.videos().insert(
        part="snippet,status",
        body=long_body,
        media_body=MediaFileUpload(str(long_video), chunksize=10 * 1024 * 1024, resumable=True),
    )
    long_resp = None
    while long_resp is None:
        status, long_resp = long_req.next_chunk()
        if status:
            print(f"Long-Form Upload Progress: {int(status.progress() * 100)}%")
    long_video_id = long_resp["id"]
    long_video_url = f"https://youtu.be/{long_video_id}"
    print(f"Long-Form Uploaded! Video URL: {long_video_url}")

    if thumb_file.exists():
        youtube.thumbnails().set(
            videoId=long_video_id,
            media_body=MediaFileUpload(str(thumb_file)),
        ).execute()
        print(f"Custom Thumbnail ({thumb_file.name}) applied to Long-Form video.")

    # 2. Upload 9:16 Short Video referencing the Long-Form Video
    print(f"Uploading 9:16 Short: {ep['short_title']}...")
    short_description = build_short_description(
        ep=ep,
        long_video_id=long_video_id,
        channel_handle=channel_handle,
        playlist_url=playlist_url,
    )
    short_body = {
        "snippet": {
            "title": ep["short_title"],
            "description": short_description,
            "tags": ["shorts", "white noise", ep["character"], ep["show"]],
            "categoryId": "24",
        },
        "status": {
            "privacyStatus": privacy,
            "selfDeclaredMadeForKids": False,
        },
    }
    short_req = youtube.videos().insert(
        part="snippet,status",
        body=short_body,
        media_body=MediaFileUpload(str(short_video), chunksize=-1, resumable=True),
    )
    short_resp = short_req.execute()
    short_video_id = short_resp["id"]
    short_video_url = f"https://youtube.com/shorts/{short_video_id}"
    print(f"Short Uploaded! Short URL: {short_video_url}")

    # 3. Auto-post top-level comments on both videos (ready to Pin in 1 click)
    post_top_comment(
        youtube,
        long_video_id,
        (
            f"Soundbyte triggers at 0:03 (\"{ep['quote']}\") then blends into the {ep.get('noise_color', 'brown')} noise loop. "
            f"Which character + exact line should interrupt the static next? Top reply gets rendered next!"
        ),
    )
    post_top_comment(
        youtube,
        short_video_id,
        f"🎧 Full 1-Hour Sleep Version: {long_video_url} — Who should interrupt the static next?",
    )

    # 4. Save live YouTube URLs back to character_rotation_catalog.json so future uploads cross-link automatically
    ep["long_video_url"] = long_video_url
    ep["short_video_url"] = short_video_url
    ep["status"] = "uploaded"
    catalog_path.write_text(json.dumps(episodes, indent=4), encoding="utf-8")
    print("Saved uploaded URLs to character_rotation_catalog.json for future cross-linking.")
    print("In YouTube Studio -> Shorts -> Edit -> set 'Related Video' to the Long-Form video above.")


def sync_catalog_metadata(
    channel_handle: str = "@CartoonWhiteNoise",
    playlist_url: str = "",
    request_url: str = "",
) -> int:
    base_dir = Path(__file__).resolve().parent
    catalog_path = base_dir / "character_rotation_catalog.json"
    episodes = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
    for ep in episodes:
        long_vid = ep.get("long_video_url", "https://youtu.be/<LONG_VIDEO_ID>").split("/")[-1]
        ep["long_description"] = build_long_description(
            ep=ep,
            all_episodes=episodes,
            channel_handle=channel_handle,
            playlist_url=playlist_url,
            request_url=request_url,
        )
        ep["short_description"] = build_short_description(
            ep=ep,
            long_video_id=long_vid,
            channel_handle=channel_handle,
            playlist_url=playlist_url,
        )
        ep["pinned_comment"] = (
            f"Soundbyte triggers at 0:03 (\"{ep['quote']}\") then blends into the "
            f"{ep.get('noise_color', 'brown')} noise loop. "
            f"Which character + exact line should interrupt the static next? Top reply gets rendered next!"
        )
    catalog_path.write_text(json.dumps(episodes, indent=4, ensure_ascii=False), encoding="utf-8")
    return len(episodes)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--episode-id", default="ep01-eustace-stupid-dog")
    parser.add_argument("--client-secret", default="client_secret.json")
    parser.add_argument("--privacy", default="public", choices=["public", "unlisted", "private"])
    parser.add_argument("--channel-handle", default=os.environ.get("YT_CHANNEL_HANDLE", "@CartoonWhiteNoise"))
    parser.add_argument("--playlist-url", default=os.environ.get("YT_PLAYLIST_URL", ""))
    parser.add_argument("--request-url", default=os.environ.get("YT_REQUEST_URL", ""))
    parser.add_argument("--sync-catalog", action="store_true", help="Refresh descriptions and pinned comments in character_rotation_catalog.json")
    args = parser.parse_args()
    if args.sync_catalog:
        count = sync_catalog_metadata(
            channel_handle=args.channel_handle,
            playlist_url=args.playlist_url,
            request_url=args.request_url,
        )
        print(f"Synced descriptions, links, chapters, and pinned comments across {count} episodes in character_rotation_catalog.json.")
    else:
        upload_episode_pair(
            episode_id=args.episode_id,
            client_secret_path=Path(args.client_secret),
            privacy=args.privacy,
            channel_handle=args.channel_handle,
            playlist_url=args.playlist_url,
            request_url=args.request_url,
        )
