%%%----------------------------------------------------------------------
%%% File    : mod_stanza_ack.erl
%%% Author  : Kay Tsar <kay@mingism.com>
%%% Purpose : Message Receipts XEP-0184 0.5
%%% Created : 25 May 2013 by Kay Tsar <kay@mingism.com>
%%% Usage   : Add the following line in modules section of ejabberd.cfg:
%%%              {mod_stanza_ack,  [{host, "zilan"}]}
%%%
%%%
%%% Copyright (C) 2013-The End of Time   Mingism
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%----------------------------------------------------------------------

-module(mod_stanza_ack).

-behaviour(gen_mod).


-include("logger.hrl").
-include("ejabberd.hrl").
-include("jlib.hrl").

-type host()    :: string().
-type name()    :: string().
-type value()   :: string().
-type opts()    :: [{name(), value()}, ...].

-define(NS_RECEIPTS, <<"urn:xmpp:receipts">>).
-define(TYPE_RECEIPTS, <<"chat">>).
-define(EJABBERD_DEBUG, true).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/2, stop/1]).
-export([on_user_send_packet/4, send_ack_response/5]).

-spec start(host(), opts()) -> ok.
start(Host, Opts) ->
	mod_disco:register_feature(Host, ?NS_RECEIPTS),
	ejabberd_hooks:add(user_send_packet, Host, ?MODULE, on_user_send_packet, 10),
	ok.

-spec stop(host()) -> ok.
stop(Host) ->
	ejabberd_hooks:delete(user_send_packet, Host, ?MODULE, on_user_send_packet, 10),
	ok.

%% ====================================================================
%% Internal functions
%% ====================================================================

on_user_send_packet(Packet, _C2SState, From, To) ->
    RegisterFromJid = <<"dev@mm.io">>, %used in ack stanza

    case xml:get_tag_attr_s(<<"type">>, Packet) of
        %%Case: Return ack that the chat message has been received by the server
        <<"chat">> ->
            RegisterToJid = From, %used in ack stanza
            send_ack_response(From, To, Packet, RegisterFromJid, RegisterToJid);
        <<"groupchat">> ->
            RegisterToJid = From, %used in ack stanza
            send_ack_response(From, To, Packet, RegisterFromJid, RegisterToJid);
        %%TODO:Case: ack that the jingle for filetransfer has been received by the server
        _ ->
        ok
    end,
    Packet.

send_ack_response(From, To, Pkt, RegisterFromJid, RegisterToJid) ->
    ReceiptId = xml:get_tag_attr_s(<<"id">>, Pkt),
    XmlBody = 	 #xmlel{name = <<"message">>,
              		    attrs = [{<<"from">>, From}, {<<"to">>, To}, {<<"type">>, ?TYPE_RECEIPTS}], 
              		    children =
              			[#xmlel{name = <<"received">>,
              				attrs = [{<<"xmlns">>, ?NS_RECEIPTS}, {<<"id">>, ReceiptId}],
              				children = []}]},
    ejabberd_router:route(jlib:string_to_jid(RegisterFromJid), RegisterToJid, XmlBody).