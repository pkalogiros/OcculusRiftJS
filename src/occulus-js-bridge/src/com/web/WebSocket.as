package com.web
{
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	/**
	 * Tried to extend flash.net.Socket, but to no avail,
	 * while casting from "WebSocket" to Socket did work, 
	 * casting Socket to WebSocket only resulted in error, therefore we 
	 *  use a wrapper arround the Socket with functions that describe how it should seek info
	 * */
	public class WebSocket
	{
		/** contains actual sendMessage Function **/
		private var _sendMessage:Function = null;
		/** contains the Function that runs on each message received **/
		private var _receiveMessage:Function = null;
		private var _sendMessageBytes:Function = null;
		
		/** type / draft of websocket **/
		public var type:String	=	null;
		/** actual socket, that will act as a websocket one **/
		public var socket:Socket = null;

		/**
		 *	WebSocket Class, contains "shortcuts" to make WebSocket handling easier
		 * 
		 *	@param	host - Host String
		 *	@param	port - Port Num
		 *	@param	_sendMessage - how the String will be sent
		 **/
		public function WebSocket( socket_to_extend:Socket, type:String )
		{
			this.socket = socket_to_extend;
			this.type = type;
		}
		
		public function setSendMessage( set_message:Function ) : void
		{
			this._sendMessage = set_message;
		}
		public function setSendMessageBytes( set_message:Function ) : void
		{
			this._sendMessageBytes = set_message;
		}
		
		/**
		 *	Sends Message to the client, this function is dynamic for every active websocket,
		 *	set at its creation
		 * 
		 *	@param	message - String to send
		 *	@param	len - length of the message
		 **/
		public function sendMessage( message:String, len:int = 0 ) : void
		{
			this._sendMessage( message, len );
		}
		public function sendBytes( message:ByteArray ) : void
		{
			this._sendMessageBytes( message );
		}
		
		/**
		 *	Function that will process the received data
		 **/
		public function receiveFrom( set_receive:Function ) : void
		{
			if( set_receive != null ) {
				this._receiveMessage = set_receive;	
				this.socket.addEventListener( ProgressEvent.SOCKET_DATA, this._receiveMessage );
			}
		}
		
		/**
		 *	Force - terminates the socket 
		 **/
		public function terminate() : void
		{
			if( this.socket && this.socket.connected ) {
				this.socket.flush();
				this.socket.close();
			}
			this.socket.dispatchEvent( new Event(Event.CLOSE, true) );
		}
	}
}