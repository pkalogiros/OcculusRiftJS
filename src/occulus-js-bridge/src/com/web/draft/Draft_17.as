package com.web.draft
{	
	import com.adobe.crypto.SHA1;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import mx.utils.Base64Encoder;
	import com.web.config.GlobalModel;
	import com.web.WebSocket;
	import com.web.WebSocketMessager;

	/**
	 * Chrome, Firefox, IE, Opera
	 **/
	public final class Draft_17
	{
		private var _webSocket:WebSocket;
		public function Draft_17()
		{
		}
		
		public function connection( socket:Socket, str:String, bytes:ByteArray, port:int ) : WebSocket
		{
			var requestArr:Array = str.split('\n'),
				reqLen:int = requestArr.length,
				host:String;

			_webSocket = new WebSocket( socket, 'Draft_17' );
			var key:String = "";
			
			_webSocket.setSendMessage( _message );
			_webSocket.setSendMessageBytes( _messageBytes );
			_webSocket.receiveFrom( _receiveFromSocket );

			while( reqLen-- > 0 ) {
				if( requestArr[ reqLen ].indexOf( 'Host:' ) !== -1 )
				{
					host = requestArr[ reqLen ].split(' ')[1].replace('\r','');
					if( host.indexOf(':') === -1 )
						host +=  ":" + port;
				}
				else if( requestArr[ reqLen ].indexOf( 'Key' ) !== -1 ) {
					key =  requestArr[ reqLen ].substr( requestArr[ reqLen ].indexOf(': ') + 2 );
				}
			}
			
			if( host.indexOf('http://') !== -1 )
				host = host.replace('http://','');
			else if( host.indexOf('https://') !== -1 )
				host = host.replace('https://','');
			
			
			key = key.replace('\r','');
			key = SHA1.hash( (key + "" + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11") );
			
			var myBytes:ByteArray = SHA1.digest;
			
			var base64:Base64Encoder = new Base64Encoder();
			base64.encodeBytes( myBytes );
			key = base64.toString();
			
			var headers:String = "HTTP/1.1 101 Web Socket Protocol Handshake\r\n";
			headers += "WebSocket-Location: ws://" + host + "/\r\n";
			headers += "Connection: Upgrade\r\n";
			headers += "Upgrade: WebSocket\r\n";
			headers += "WebSocket-Origin: http://" + host + "\r\n";
			headers += "Sec-WebSocket-Accept: " + key.replace('\n','') + "\r\n";
			headers += "\r\n";
			
			socket.writeUTFBytes( headers );
			socket.flush();
			
			return _webSocket;
		}
		
		/**
		 * _message( String, int ) (public)
		 * Send STRING message to the socket_array[ INDEX ] socket
		 * 
		 * @param str:String - Message to send
		 * @param index:int - Socket index
		 **/
		private function _message( str:String, group:int = 0, index:int = 0 ) : void
		{
			var header:ByteArray = new ByteArray(),
				data_length:int = str.length,
				socket_array:Array = GlobalModel.getInstance().WServer.socket_array;
			
			header.writeByte(  0x81 );
			
			if( data_length < 126 )
				header.writeByte( data_length );
			
			else if( data_length < 65536 )
			{
				// If 126, the following 2 bytes interpreted as a 16
				// bit unsigned integer are the payload length. 
				header.writeByte( 126 );
				header.writeByte( data_length >> 8 );
				header.writeByte( data_length & 0xFF );
			}
			else
			{
				// If 127, the following 8 bytes interpreted as a 64-bit unsigned integer (the 
				// most significant bit MUST be 0) are the payload length. e
				header.writeByte(127);
				header.writeByte((data_length & 0xFF00000000000000) >> 56);
				header.writeByte((data_length & 0xFF000000000000) >> 48);
				header.writeByte((data_length & 0xFF0000000000) >> 40);
				header.writeByte((data_length & 0xFF00000000) >> 32);
				header.writeByte((data_length & 0xFF000000) >> 24);
				header.writeByte((data_length & 0xFF0000) >> 16);
				header.writeByte((data_length & 0xFF00 ) >> 8);
				header.writeByte( data_length & 0xFF );
			}

			try
			{
				this._webSocket.socket.writeBytes( header, 0, header.bytesAvailable );
				
				for( var i:int = 0; i < data_length; ++i )
					this._webSocket.socket.writeByte( str.charCodeAt(i) );
				
				this._webSocket.socket.flush();
			}
			catch( e:* )
			{
				this._webSocket.terminate();
				// socket_array[ 0 ] = null;
				// socket_array[ 1 ] = null;
				// socket_array[ 2 ] = null;
				
				// GlobalModel.getInstance().WServer.socket_array = [ [], [], [] ];
			}
		}
		private function _messageBytes( bytes:ByteArray ) : void
		{
			var header:ByteArray = new ByteArray(),
				data_length:int = bytes.bytesAvailable,
				socket_array:Array = GlobalModel.getInstance().WServer.socket_array;
			
			header.writeByte(  0x82 );
			if( data_length < 127 ) {
				header.writeByte(  0x7E );
				header.writeByte( data_length );
			}
			if( data_length < 65535 )
			{
				// If 126, the following 2 bytes interpreted as a 16
				// bit unsigned integer are the payload length. 
				header.writeByte(  0x7E );
				header.writeByte( data_length >> 8 );
				header.writeByte( data_length & 0xFF );
			}
			else
			{
				// If 127, the following 8 bytes interpreted as a 64-bit unsigned integer (the 
				// most significant bit MUST be 0) are the payload length. e
				header.writeByte( 0x7F );
				header.writeByte((data_length & 0xFF00000000000000) >> 56);
				header.writeByte((data_length & 0xFF000000000000) >> 48);
				header.writeByte((data_length & 0xFF0000000000) >> 40);
				header.writeByte((data_length & 0xFF00000000) >> 32);
				header.writeByte((data_length & 0xFF000000) >> 24);
				header.writeByte((data_length & 0xFF0000) >> 16);
				header.writeByte((data_length & 0xFF00 ) >> 8);
				header.writeByte( data_length & 0xFF );
			}
			
			try
			{
				this._webSocket.socket.writeBytes( header, 0, header.bytesAvailable );
				this._webSocket.socket.writeBytes( bytes );
				this._webSocket.socket.flush();
			}
			catch( e:* )
			{
				this._webSocket.terminate();
				// socket_array[ 0 ] = null;
				// socket_array[ 1 ] = null;
				// socket_array[ 2 ] = null;
				
				// GlobalModel.getInstance().WServer.socket_array = [ [], [], [] ];
			}
		}

		/**
		 * _receiveFromSocket( event:ProgressEvent ) (public)
		 * Send STRING message to the socket_array[ INDEX ] socket
		 * 
		 * @param str:String - Message to send
		 * @param index:int - Socket index
		 **/
		private function _receiveFromSocket( e:ProgressEvent ) : String
		{
			var socket:Socket = e.target as Socket,
				bytes:ByteArray = new ByteArray();
			
			socket.readBytes( bytes );
			
			var firstByte:int = bytes.readByte(),
				secondByte:int = bytes.readByte(),
			
				fin:Boolean    = Boolean( firstByte  & 0x80 ),
				rsv1:Boolean   = Boolean( firstByte  & 0x40 ),
				rsv2:Boolean   = Boolean( firstByte  & 0x20 ),
				rsv3:Boolean   = Boolean( firstByte  & 0x10 ),
				mask:Boolean   = Boolean( secondByte & 0x80 );
			
			var opcode:int = firstByte  & 0x0F,
				_length:int = secondByte & 0x7F;
			
			if( fin )
			{
				if( mask )
				{
					//grabbing the mask
					var masking:Array = [];
					
					masking[0] = bytes.readByte();
					masking[1] = bytes.readByte();
					masking[2] = bytes.readByte();
					masking[3] = bytes.readByte();
				}
				
				var binaryPayload:ByteArray = new ByteArray();
				binaryPayload.endian = Endian.BIG_ENDIAN;
				bytes.readBytes(binaryPayload, 0, _length);
				binaryPayload.position = 0;
			}
			
			var RESULT:Array = [],
				push:ByteArray = new ByteArray();
			
			for( var k:int = 0; k < _length; ++k )
			{
				RESULT[ k ] = binaryPayload.readByte() ^ masking[ k % 4 ];
				push.writeByte( RESULT[ k ] );
			}
			push.position = 0;
			WebSocketMessager.getPurpose( push.readUTFBytes( push.bytesAvailable ), this._webSocket );
			
			return "";
			// return push.readUTFBytes( push.bytesAvailable );
		}
	//end
	}
}