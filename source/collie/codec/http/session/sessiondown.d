﻿module collie.codec.http.session.sessiondown;

import collie.channel;
import collie.codec.http.session.httpsession;
import std.socket;
import collie.socket.tcpsocket;
import collie.socket.eventloop;

@trusted class PipelineSessionDown : HandlerAdapter!(ubyte[]),SessionDown
{
	@property httpSession(){return _session;}
	@property httpSession(HTTPSession session){_session = session;}

	override void timeOut(Context ctx) {
		if(_session)
			_session.onTimeout();
	}

	override void transportActive(Context ctx) {
		TCPSocket sock = cast(TCPSocket)context.pipeline.transport;
		_local = sock.localAddress;
		_remote = sock.remoteAddress;
		_loop = sock.eventLoop();
		if(_session)
			_session.onActive();
	}

	override void transportInactive(Context ctx) {
		if(_session)
			_session.inActive();
	}

	override void read(Context ctx,ubyte[] msg) {
		if(_session)
			_session.onRead(msg);
	}

	override void httpClose() {
		close(context);
	}

	override void httpWrite(ubyte[] data,void delegate(ubyte[], size_t) cback) {
		write(context,data,cback);
	}

	override Address localAddress() {
		return _local;
	}

	override Address remoteAddress() {
		return _remote;
	}

	override  void post(void delegate() call){
		_loop.post(call);
	}

private:
	HTTPSession _session;
	Address _local;
	Address _remote;
	EventLoop _loop;
}


import collie.socket.server.tcpserver;
import collie.socket.server.connection;
import std.exception;

@trusted class HTTPConnection : ServerConnection,SessionDown
{
	this(TCPSocket sock)
	{
		super(sock);
		_loop = sock.eventLoop();
	}

	@property httpSession(){return _session;}
	@property httpSession(HTTPSession session){_session = session;}

	override void httpClose() {
		close();
	}
	override void httpWrite(ubyte[] data,void delegate(ubyte[], size_t) cback) {
		write(data,cback);
	}
	override Address localAddress() {
		return tcpSocket.localAddress;
	}

	override Address remoteAddress() {
		return tcpSocket.remoteAddress;
	}

	override  void post(void delegate() call){
		_loop.post(call);
	}
protected:
	override void onTimeOut() nothrow {
		if(_session)
			collectException(_session.onTimeout());
	}

	override void onClose() nothrow {
		if(_session)
			collectException(_session.inActive());
	}

	override  void onActive() nothrow {
		if(_session)
			collectException(_session.onActive());
	}

	override  void onRead(ubyte[] data) nothrow {
		if(_session)
			collectException(_session.onRead(data));
	}


private:
	HTTPSession _session;
	EventLoop _loop;
}