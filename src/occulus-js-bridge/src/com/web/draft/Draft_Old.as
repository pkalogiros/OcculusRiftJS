package com.web.draft
{
	import com.adobe.crypto.MD5;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import com.web.config.GlobalModel;
	import com.web.WebSocket;
	import com.web.WebSocketMessager;
	
	/**
	 *	Opera Mobile, iOs 4
	 **/
	public class Draft_Old
	{
		public var webSocket:WebSocket = null;
		
		public function Draft_Old()
		{
		}
		
		public function connection( socket:Socket, str:String, bytes:ByteArray, port:int ) : WebSocket
		{
			//checking to see 
			var webSocket:WebSocket = new WebSocket( socket, 'Draft_Old' );
			this.webSocket = webSocket;

			webSocket.setSendMessage( _message );
			webSocket.setSendMessageBytes( _messageBytes );
			webSocket.receiveFrom( _receiveFromSocket );
			
			//old version (ios, safari)
			var messageLines:Array = str.split("\n");
			var fields:Object = {};
			var requestedURL:String = "";
			for(var i:uint = 0; i < messageLines.length; i++)
			{ 
				var line:String = messageLines[i];
				if(i == 0)
				{
					var getSplit:Array = line.split(" ");
					if(getSplit.length > 1)
					{
						requestedURL = getSplit[1];
					}
				}
				else
				{
					var index:int = line.indexOf(":");
					if(index > -1)
					{
						var key:String = line.substr( 0, index );
						fields[key] = line.substr( index + 1 ).replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2" );
					}
				}
			}
			//check the websocket version
			if(fields["Sec-WebSocket-Version"] != null)
			{
				// NOT SUPPORTED
			}
			else
			{
				if(fields["Sec-WebSocket-Key1"] != null && fields["Sec-WebSocket-Key2"] != null)
				{
					//draft-ietf-hybi-thewebsocketprotocol-00
					//send a response
					var result:* = fields["Sec-WebSocket-Key1"].match(/[0-9]/gi);
					var key1Nr:uint = (result is Array) ? uint(result.join("")) : 1;
					result = fields["Sec-WebSocket-Key1"].match(/ /gi);
					var key1SpaceCount:uint = (result is Array) ? result.length : 1;
					var key1Part:Number = key1Nr / key1SpaceCount;
					
					result = fields["Sec-WebSocket-Key2"].match(/[0-9]/gi);
					var key2Nr:uint = (result is Array) ? uint(result.join("")) : 1;
					result = fields["Sec-WebSocket-Key2"].match(/ /gi);
					var key2SpaceCount:uint = (result is Array) ? result.length : 1;
					var key2Part:Number = key2Nr / key2SpaceCount;
					
					//calculate binary md5 hash
					var bytesToHash:ByteArray = new ByteArray();
					bytesToHash.writeUnsignedInt(key1Part);
					bytesToHash.writeUnsignedInt(key2Part);
					bytesToHash.writeBytes(bytes, bytes.length - 8);
					
					//hash it
					var hash:String = MD5.hashBytes(bytesToHash);
					
					var response:String = "HTTP/1.1 101 WebSocket Protocol Handshake\r\n" +
						"Upgrade: WebSocket\r\n" +
						"Connection: Upgrade\r\n" +
						"Sec-WebSocket-Origin: " + fields["Origin"] + "\r\n" +
						"Sec-WebSocket-Location: ws://" + fields["Host"] + requestedURL + "\r\n" +
						"\r\n";
					var responseBytes:ByteArray = new ByteArray();
					responseBytes.writeUTFBytes(response);
					
					for(i = 0; i < hash.length; i += 2)
					{
						responseBytes.writeByte(parseInt(hash.substr(i, 2), 16));
					}
					
					responseBytes.writeByte(0);
					responseBytes.position = 0;
					socket.writeBytes(responseBytes);
					socket.flush();
				}
			}
			
			return webSocket;
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
			
			header.writeByte(  0xFF );
			header.writeByte( data_length );
			
			try
			{
				this.webSocket.socket.writeBytes( header, 0, header.bytesAvailable );
				
				for( var i:int = 0; i < data_length; ++i )
					this.webSocket.socket.writeByte( str.charCodeAt(i) );
				
				this.webSocket.socket.flush();
			}
			catch( e:* )
			{
				this.webSocket.terminate();
			}
		}
		
		private function _messageBytes( bytes:ByteArray ) : void
		{
			var header:ByteArray = new ByteArray(),
				data_length:int = bytes.bytesAvailable,
				socket_array:Array = GlobalModel.getInstance().WServer.socket_array;
			
			header.writeByte(  0xFF );
			header.writeByte( data_length );
			
			try
			{
				this.webSocket.socket.writeBytes( header, 0, header.bytesAvailable );
				this.webSocket.socket.writeBytes( bytes );
				this.webSocket.socket.flush();
			}
			catch( e:* )
			{
				this.webSocket.terminate();
			}
		}
		
		/**
		 * _receiveFromSocket( bytes:byteArray ) (public)
		 * Send STRING message to the socket_array[ INDEX ] socket
		 * 
		 * @param str:String - Message to send
		 * @param index:int - Socket index
		 ***/
		private function _receiveFromSocket( event:ProgressEvent ) : String
		{
			var socket:Socket = event.target as Socket,
				bytes:ByteArray = new ByteArray();
			
				socket.readBytes( bytes );
			
			var start:int = bytes.readUnsignedByte();
			var ret:String  = "";
			
			var tempint:int = 0;
			
			while( bytes.bytesAvailable > 0 )
			{
				tempint = bytes.readByte();
				if( tempint !== -1 )
					ret +=  String.fromCharCode(tempint);
			}
			WebSocketMessager.getPurpose( ret, this.webSocket );
			
			return ret;
		}
	// end
	}
}