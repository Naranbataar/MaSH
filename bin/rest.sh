#!/bin/sh
. utils.sh

_route(){
    read -r TEXT
    COMMAND="$1"; ROUTE="$2"; TYPE="$3"; DATA_ARGS="$4"; URL_ARGS="$5"

    DATA="$(printf '%s\n' "$TEXT" \
            | format-args "$TYPE" "$DATA_ARGS" "$URL_ARGS")"
    
    ARGS="$(printf '%s\n' "$DATA" | head -n 1)"
    [ "$ARGS" = "{}" ] && ARGS=' '

    case "$TYPE" in
    'json')
        printf '%s\n' "$ARGS" \
        | dapi "$COMMAND" "$(eval "printf '%s\\n' \"$ROUTE\"")" ;;
    'url')
        printf " \n" \
        | dapi "$COMMAND" "$(eval "printf '%s\\n' \"$ROUTE\"")$ARGS" ;;
    esac
}


channel() {
    case "$1" in
    'get'|'new'|'edit'|'del'|'list'|'dm_add' \
    |'dm_remove'|'pos_edit'|'perm_edit'|'perm_delete')
        case "$1" in
        'get')
            _route 'GET' '/channels/$1' 'json' '' '.id' ;;
        'new')
            DATA_ARGS='name,type,topic,bitrate,user_limit,rate_limit_per_user'
            DATA_ARGS="$DATA_ARGS,position,permission_overwrites,parent_id"
            DATA_ARGS="$DATA_ARGS,nsfw"
            _route 'POST' '/guilds/$1/channels' 'json' "$DATA_ARGS" \
                  '.guild' ;;
        'edit')
            DATA_ARGS='name,topic,bitrate,user_limit,rate_limit_per_user'
            DATA_ARGS="$DATA_ARGS,position,permission_overwrites,parent_id"
            DATA_ARGS="$DATA_ARGS,nsfw"
            _route 'PATCH' '/channels/$1' 'json' "$DATA_ARGS" '.id' ;;
        'del')
            _route 'DELETE' '/channels/$1' 'json' '' '.id' ;;
        'list')
            _route 'GET' '/guilds/$1/channels' 'json' '' '.guild' ;;
        'dm_add')
            _route 'PUT' '/channels/$1/recipients/$2' 'json' '' '.id,.user' ;;
        'dm_remove')
            _route 'DELETE' '/channels/$1/recipients/$2' 'json' ''
                  '.id,.user' ;;
        'pos_edit')
            _route 'PATCH' '/guilds/$1/channels' 'json' 'data' '.guild' ;;
        'perm_edit')
            _route 'PUT' '/channels/$1/permissions/$2' 'json' 'allow,deny,type'
                  '.channel,.id' ;;
        'perm_delete')
            _route 'DELETE' '/channels/$1/permissions/$2' 'json' ''
                  '.channel,.id' ;;
        esac ;;
    *)
        cat ../usage/rest/channel >&2
        exit 1 ;;
    esac
}

emoji() {
    case "$1" in
    'get'|'new'|'edit'|'del'|'list')
        case "$1" in
        'get')
            _route 'GET' '/guilds/$1/emojis/$2' 'json' '' '.guild,.id' ;;
        'new')
            _route 'POST' '/guilds/$1/emojis' 'json' 'name,image,roles' \
                  '.guild' ;;
        'edit')
            _route 'PATCH' '/guilds/$1/emojis/$2' 'json' 'name,roles' \
                  '.guild,.id' ;;
        'del')
            _route 'DELETE' '/guilds/$1/emojis/$2' 'json' '' '.guild,.id' ;;
        'list')
            _route 'GET' '/guilds/$1/emojis' 'json' '' '.guild' ;;
        esac ;;
    *)
        cat ../usage/rest/emoji >&2
        exit 1 ;;
    esac
}

guild(){
    case "$1" in
    'get'|'new'|'edit'|'del'|'embed_get'|'embed_edit' \
    |'audit_log'|'vanity_url'|'widget')
        case "$1" in
        'get')
            _route 'GET' '/guilds/$1' 'json' '' '.guild' ;;
        'new')
            DATA_ARGS='name,region,icon,verification_level'
            DATA_ARGS="$DATA_ARGS,default_message_notifications"
            DATA_ARGS="$DATA_ARGS,explicit_content_filter,roles,channels"
            _route 'POST' '/guilds' 'json' "$DATA_ARGS" '' ;;
        'edit')
            DATA_ARGS='name,region,verification_level'
            DATA_ARGS="$DATA_ARGS,default_message_notifications"
            DATA_ARGS="$DATA_ARGS,explicit_content_filter,afk_channel_id"
            DATA_ARGS="$DATA_ARGS,afk_timeout,icon,owner_id,splash"
            DATA_ARGS="$DATA_ARGS,system_channel_id"
            _route 'PATCH' '/guilds/$1' 'json' "$DATA_ARGS" '.guild' ;;
        'del')
            _route 'DELETE' '/guilds/$1' 'json' '' '.guild' ;;
        'embed_get')
            _route 'GET' '/guilds/$1/embed' 'json' '' '.guild' ;;
        'embed_edit')
            _route 'PATCH' '/guilds/$1/embed' 'json' 'enabled,channel_id' \
                  '.guild' ;;
        'audit_log')
            DATA_ARGS='user_id,action_type,before,limit'
            _route 'GET' '/guilds/$1/audit-logs' 'url' "$DATA_ARGS" '.guild' ;;
        'vanity_url')
            _route 'GET' '/guilds/$1/vanity-url' 'json' '' '.guild' ;;
        'widget')
            _route 'GET' '/guilds/$1/widget.png' 'url' 'style' '.guild' ;;
        esac ;;
    *)
        cat ../usage/rest/guild >&2
        exit 1 ;;
    esac
}

integration() {
    case "$1" in
    'get'|'new'|'edit'|'del'|'sync')
        case "$1" in
        'get')
            _route 'GET' '/guilds/$1/integrations' 'json' '' '.guild' ;;
        'new')
            _route 'POST' '/guilds/$1/integrations' 'json' 'id,type' \
                   '.guild' ;;
        'edit')
            _route 'PATCH' '/guilds/$1/integrations/$2' 'json' \
                   'expire_behavior,expire_grace_period,enable_emoticons' \
                   '.guild,.id' ;;
        'del')
            _route 'DELETE' '/guilds/$1/integrations/$2' 'json' '' \
                   '.guild,.id' ;;
        'sync')
            _route 'POST' '/guilds/$1/integrations/$2/sync' 'json' '' \
                   '.guild,.id' ;;
        esac ;;
    *)
        cat ../usage/rest/integration >&2
        exit 1 ;;
    esac
}

invite() {
    case "$1" in
    'get'|'new'|'del'|'list_ch'|'list_g')
        case "$1" in
        'get')
            _route 'GET' '/invites/$1' 'json' '' '.code' ;;
        'new')
            _route 'POST' '/channels/$1/invites' 'json' \
                   'max_age,max_uses,temporary,unique' '.channel' ;;
        'del')
            _route 'DELETE' '/invites/$1' 'json' '' '.code' ;;
        'list_ch')
            _route 'GET' '/channels/$1/invites' 'json' '' '.id' ;;
        'list_g')
            _route 'GET' '/guilds/$1/invites' 'json' '' '.id' ;;
        esac ;;
    *)
        cat ../usage/rest/invite >&2
        exit 1 ;;
    esac
}

member() {
    case "$1" in
    'get'|'new'|'edit'|'del'|'list'|'my_nick_edit')
        case "$1" in
        'get')
            _route 'GET' '/guilds/$1/members/$2' 'json' '' '.guild,.id' ;;
        'new')
            _route 'PUT' '/guilds/$1/members/$2' 'json' \
                   'access_token,nick,roles,mute,deaf' '.guild,.id' ;;
        'edit')
            _route 'PATCH' '/guilds/$1/members/$2' 'json' \
                   'nick,roles,mute,deaf,channel_id' '.guild,.id' ;;
        'del')
            _route 'DELETE' '/guilds/$1/members/$2' 'json' '' '.guild,.id' ;;
        'list')
            _route 'GET' '/guilds/$1/members' 'url' 'limit,after' '.guild' ;;
        'rename_me')
            _route 'PATCH' '/guilds/$1/members/@me/nick' 'json' 'nick' \
                   '.guild' ;;
        esac ;;
    *)
        cat ../usage/rest/member >&2
        exit 1 ;;
    esac
}

message() {
    case "$1" in
    'type'|'get'|'send'|'edit'|'delete'|'pin'|'unpin'|'pins'|'bulk_get' \
    |'bulk_delete')
        case "$1" in
        'type')
            _route 'POST' '/channels/$1/typing' 'json' '' '.channel' ;;
        'get')
            _route 'GET' '/channels/$1/messages/$2' 'json' '' '.channel,.id' ;;
        'send')
            read -r TEXT
            DATA="$(printf '%s\n' "$TEXT" | format-args json \
                                            'content,embed,nonce,tts' \
                                            '.files,.channel')"
        set -- "$(printf '%s\n' "$DATA" | tail -n +2)"
        ARGS="$(printf '%s\n' "$DATA" | head -n 1)"
            if [ "$1" = 'null' ]; then
                printf '%s\n' "$ARGS" | dapi POST "/channels/$2/messages"
            else
                printf '%s\n' "$ARGS" | dapi @FILES "/channels/$2/messages" \
                                        "$1"
            fi ;;
        'edit')
            _route 'PATCH' '/channels/$1/messages/$2' 'json' 'content,embed' \
                  '.channel,.id' ;;
        'delete')
            _route 'DELETE' '/channels/$1/messages/$2' 'json' '' \
                  '.channel,.id' ;;
        'pin')
            _route 'PUT' '/channels/$1/pins/$2' 'json' '' '.channel,.id' ;;
        'unpin')
            _route 'DELETE' '/channels/$1/pins/$2' 'json' '' '.channel,.id' ;;
        'pins')
            _route 'GET' '/channels/$1/pins' 'json' '' '.channel' ;;
        'bulk_get')
            _route 'GET' '/channels/$1/messages' 'url' \
                   'before,after,around,limit' '.channel' ;;
        'bulk_delete')
            _route 'POST' '/channels/$1/messages/bulk-delete' 'json' \
                   'messages' '.channel' ;;
        esac ;;
    *)
        cat ../usage/rest/message >&2
        exit 1 ;;
    esac
}

moderation() {
    case "$1" in
    'ban'|'unban'|'get_ban'|'get_bans'|'prune'|'count_prune')
        case "$1" in
        'ban')
            _route 'PUT' '/guilds/$1/bans/$2' 'url' \
                   'reason,delete-message-days' '.guild,.id' ;;
        'unban')
            _route 'DELETE' '/guilds/$1/bans/$2' 'json' '' '.guild,.id' ;;
        'get_ban')
            _route 'GET' '/guilds/$1/bans/$2' 'json' '' '.guild,.id' ;;
        'get_bans')
            _route 'GET' '/guilds/$1/bans' 'json' '' '.guild' ;;
        'prune')
            _route 'POST' '/guilds/$1/prune' 'url' \
                   'days,compute-prune-count' '.guild' ;;
        'count_prune')
            _route 'GET' '/guilds/$1/prune' 'url' 'days' '.guild' ;;
        esac ;;
    *)
        cat ../usage/rest/moderation >&2
        exit 1 ;;
    esac
}

reaction() {
    case "$1" in
    'get'|'add'|'del'|'del_mod'|'del_all')
        case "$1" in
        'get')
            _route 'GET' "/channels/\$1/messages/\$2/reactions/\$3" 'url' \
                   'before,after,limit' '.channel,.id,.emoji' ;;
        'add')
            _route 'PUT' "/channels/\$1/messages/\$2/reactions/\$3/@me" \
                   'json' '' '.channel,.id,.emoji' ;;
        'del')
            _route 'DELETE' "/channels/\$1/messages/\$2/reactions/\$3/@me" \
                   'json' '' '.channel,.id,.emoji' ;;
        'del_mod')
            _route 'DELETE' "/channels/\$1/messages/\$2/reactions/\$3/\$4" \
                   'json' '' '.channel,.id,.emoji,.author' ;;
        'del_all')
            _route 'DELETE' "/channels/\$1/messages/\$2/reactions" \
                   'json' '' '.channel,.id' ;;
        esac ;;
    *)
        cat ../usage/rest/moderation >&2
        exit 1 ;;
    esac
}

role() {
    case "$1" in
    'new'|'edit'|'del'|'list'|'give'|'take'|'pos_edit')
        case "$1" in
        'new')
            _route 'POST' '/guilds/$1/roles' 'json' \
                   'name,permissions,color,hoist,mentionable' '.guild' ;;
        'edit')
            _route 'PATCH' '/guilds/$1/roles/$2' 'json' \
                   'name,permissions,color,hoist,mentionable' '.guild,.id' ;;
        'del')
            _route 'DELETE' '/guilds/$1/roles/$2' 'json' '' '.guild,.id' ;;
        'list')
            _route 'GET' '/guilds/$1/roles' 'json' '' '.guild' ;;
        'give')
            _route 'PUT' '/guilds/$1/members/$2/roles/$3' 'json' '' \
                   '.guild,.user,.id' ;;
        'take')
            _route 'DELETE' '/guilds/$1/members/$2/roles/$3' 'json' '' \
                   '.guild,.user,.id' ;;
        'pos_edit')
            _route 'PATCH' '/guilds/$1/roles' 'json' '.data' '.guild' ;;
        esac ;;
    *)
        cat ../usage/rest/role >&2
        exit 1 ;;
    esac
}

user() {
    case "$1" in
    'get'|'edit'|'new_dm'|'dms'|'guilds'|'connections')
        case "$1" in
        'get')
            _route 'GET' '/users/$1' 'json' '' '.id' ;;
        'edit')
            _route 'PATCH' '/users/@me' 'json' 'name,avatar' '' ;;
        'new_dm')
            _route 'POST' '/users/@me/channels' 'json' 'recipient_id' '' ;;
        'dms')
            _route 'GET' '/users/@me/channels' 'json' '' '' ;;
        'guilds')
            _route 'GET' '/users/@me/guilds' 'url' 'before,after,limit' '' ;;
        'connections')
            _route 'GET' '/users/@me/connections' 'json' '' '' ;;
        esac ;;
    *)
        cat ../usage/rest/user >&2
        exit 1 ;;
    esac
}

webhook() {
    case "$1" in
    'exec'|'get'|'edit'|'del'|'list_ch'|'list_g')
        case "$1" in
        'exec')
            read -r TEXT
            DATA_ARGS='content,embeds,username,avatar_url,tts'
            URL_ARGS='.files,.id,(if .token = null then "" else "/\(.token)"'
            URL_ARGS="$URL_ARGS end)"
            DATA="$(printf '%s\n' "$TEXT" | format-args json "$DATA_ARGS" \
                                            "$URL_ARGS")"
            set -- "$(printf '%s\n' "$DATA" | tail -n +2)"
            ARGS="$(printf '%s\n' "$DATA" | head -n 1)"
            if [ "$1" = 'null' ]; then
                printf '%s\n' "$ARGS" | dapi POST "/webhooks/$2$3"
            else
                printf '%s\n' "$ARGS" | dapi @FILES "/webhooks/$2$3" "$1"
            fi ;;
        'get')
            _route 'GET' '/webhooks/$1$2' 'json' '' \
                   '.id,(if .token = null then "" else "/\(.token)" end)' ;;
        'edit')
            _route 'PATCH' '/webhooks/$1$2' 'json' '' \
                   '.id,(if .token = null then "" else "/\(.token)" end)' ;;
        'del')
            _route 'DELETE' '/webhooks/$1$2' 'json' '' '.id,.token//empty' ;;
        'list_ch')
            _route 'GET' '/channels/$1/webhooks' 'json' '' '.id' ;;
        'list_g')
            _route 'GET' '/guilds/$1/webhooks' 'json' '' '.id' ;;
        esac ;;
    *)
        cat ../usage/rest/webhook >&2
        exit 1 ;;
    esac
}
