package com.web.draft
{
	import com.adobe.crypto.SHA1;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import mx.utils.Base64Encoder;
	import com.web.WebSocket;
	import com.web.WebSocketMessager;
	
	/**
	 *	Was used for Firefox pre 11 (no longer needed) 
	 **/
	public final class Draft_10
	{
		public var webSocket:WebSocket = null;
		
		public function Draft_10()
		{
		}
		
		public function connection( socket:Socket, str:String, bytes:ByteArray, port:int ) : WebSocket
		{
			var webSocket:WebSocket = new WebSocket( socket, 'Draft_10' );
			this.webSocket = webSocket;
			
			webSocket.setSendMessage( _message );
			webSocket.setSendMessageBytes( _messageBytes );
			webSocket.receiveFrom( _receiveFromSocket );
			
			// do handyshake: (hybi-10)
			var requestArr:Array = str.split('\n');
			var key:String = requestArr[9].substr( requestArr[9].indexOf(': ') + 2 );
			key = key.replace('\r','');

			var reqLen:int = requestArr.length,
				host:String;
			
			//var shasum:String = crypto.createHash('sha1');  
			//shasum.update(key);  
			//shasum.update("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");  
			//key = shasum.digest('base64'); 
			
			key = SHA1.hash( (key + "" + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11") );
			var myBytes:ByteArray = SHA1.digest;
			
			var base64:Base64Encoder = new Base64Encoder();
			base64.encodeBytes( myBytes );
			key = base64.toString();

			var mystring:String = "HTTP/1.1 101 Switching Protocols\r\n";
			mystring += "Upgrade: websocket\r\n";
			mystring += "Connection: Upgrade\r\n";
			mystring += "Sec-WebSocket-Accept: " + key.replace('\n','') + "\r\n";
			mystring += "\r\n";
			
			socket.writeUTFBytes( mystring );
			socket.flush();
			
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
			var bt:int = 0,
				sendLen:int = 0,
				i:int,
				len:int = 0,
				stream:ByteArray = new ByteArray(),
				bytes:ByteArray,
				masks:ByteArray = new ByteArray(),
				send:ByteArray = new ByteArray(),
				fMasking:Boolean = false, //do not mask when we are sending data
				aStream:ByteArray = new ByteArray();
			
			aStream.position = 0;
			aStream.writeUTFBytes( str );
			
			try
			{
				//send basics
				bt = ( true ? 1 : 0 ) * 0x80;
				bt += ( false ? 1 : 0 ) * 0x40;
				bt += ( false ? 1 : 0 ) * 0x20;
				bt += ( false ? 1 : 0 ) * 0x10;
				bt += 0x01;
				
				stream.writeByte( bt );
				
				//length & mask
				len = ( fMasking ? 1 : 0 ) * 0x80;
				if ( aStream.length < 126 )
						len += aStream.length;
				else if ( aStream.length < 65536 )
						len += 126;
				else
					len += 127;

				stream.writeByte( len );

				if ( aStream.length >= 126 )
				{
					bytes = new ByteArray();
					if( aStream.length < 65536 )
						bytes.writeShort(str.length);
					else
						bytes.writeInt(str.length);
					//reverse?
					//if (BitConverter.IsLittleEndian) bytes = ReverseBytes(bytes);
					stream.writeBytes( bytes, 0, bytes.length );
				}
				
				//masking
				if( fMasking )
				{
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					stream.writeBytes( masks, 0, masks.length );
				}
				
				//send data
				aStream.position = 0;
				
				aStream.readBytes(send);
				
				if(fMasking)
				{
					for( i = 0; i < send.length; ++i )
					{
						send[i] = (send[i] ^ masks[i % 4]);
					}
				}
				
				stream.writeBytes( send, 0, send.length );
				
				//socket_array[ group ][ index ].writeBytes( send, 0, send.length );
				this.webSocket.socket.writeBytes( stream );
				this.webSocket.socket.flush();
			}
			catch (e:Error)
			{
				this.webSocket.terminate();
			}
		}
		
		private function _messageBytes( bytes:ByteArray ) : void
		{
			var bt:int = 0,
				sendLen:int = 0,
				i:int,
				len:int = 0,
				stream:ByteArray = new ByteArray(),
				_bytes:ByteArray,
				masks:ByteArray = new ByteArray(),
				send:ByteArray = new ByteArray(),
				fMasking:Boolean = false, //do not mask when we are sending data
				aStream:ByteArray = new ByteArray();
			
			aStream.position = 0;
			aStream.writeBytes( bytes );
			
			try
			{
				//send basics
				bt = ( true ? 1 : 0 ) * 0x80;
				bt += ( false ? 1 : 0 ) * 0x40;
				bt += ( false ? 1 : 0 ) * 0x20;
				bt += ( false ? 1 : 0 ) * 0x10;
				bt += 0x01;
				
				stream.writeByte( bt );
				
				//length & mask
				len = ( fMasking ? 1 : 0 ) * 0x80;
				if ( aStream.length < 126 )
					len += aStream.length;
				else if ( aStream.length < 65536 )
					len += 126;
				else
					len += 127;
				
				stream.writeByte( len );
				
				if ( aStream.length >= 126 )
				{
					_bytes = new ByteArray();
					if( aStream.length < 65536 )
						_bytes.writeShort(bytes.bytesAvailable);
					else
						_bytes.writeInt(bytes.bytesAvailable);
					//reverse?
					//if (BitConverter.IsLittleEndian) bytes = ReverseBytes(bytes);
					stream.writeBytes( _bytes, 0, _bytes.length );
				}
				
				//masking
				if( fMasking )
				{
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					masks.writeByte( Math.floor(Math.random() * 256) );
					stream.writeBytes( masks, 0, masks.length );
				}
				
				//send data
				aStream.position = 0;
				
				aStream.readBytes(send);
				
				if(fMasking)
				{
					for( i = 0; i < send.length; ++i )
					{
						send[i] = (send[i] ^ masks[i % 4]);
					}
				}
				
				stream.writeBytes( send, 0, send.length );
				
				//socket_array[ group ][ index ].writeBytes( send, 0, send.length );
				this.webSocket.socket.writeBytes( stream );
				this.webSocket.socket.flush();
			}
			catch (e:Error)
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
		 **/
		private function _receiveFromSocket( socketBytes:ByteArray ) : String
		{
			var messageString:String = "",
				bt:int,
				len:int,
				mask:Boolean,
				masks:Array = [0, 0, 0, 0];
			
			if( socketBytes.bytesAvailable > 0 )
			{
				bt = socketBytes.readUnsignedByte();
				
				var aReadFinal:Boolean = (bt & 0x80 ) == 0x80,
					aRes1:Boolean = ( bt & 0x40 ) == 0x40,
					aRes2:Boolean = ( bt & 0x20 ) == 0x20,
					aRes3:Boolean = ( bt & 0x10 ) == 0x10,
					aReadCode:int = ( bt & 0x0f );
				
				//mask & length
				if (socketBytes.bytesAvailable > 0)
				{
					bt = socketBytes.readUnsignedByte();
					mask = ( bt & 0x80 ) == 0x80;
					len = ( bt & 0x7F );
					if( len == 126 )
					{
						if( socketBytes.bytesAvailable > 0  )
						{
							bt = socketBytes.readUnsignedByte();
							len = bt * 0x100;
							if( socketBytes.bytesAvailable > 0 )
							{
								bt = socketBytes.readUnsignedByte();
								len = len + bt;
							}
						}
					}
					else if( len == 127 )
					{
						if( socketBytes.bytesAvailable > 0 )
						{
							bt = socketBytes.readUnsignedByte();
							len = bt * 0x100000000000000;
							bt = socketBytes.readUnsignedByte();
							
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x1000000000000;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x10000000000;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x100000000;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x1000000;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x10000;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt * 0x100;
								bt = socketBytes.readUnsignedByte();
							}
							if( socketBytes.bytesAvailable > 0 )
							{
								len = len + bt;
							}
						}
					}
					
					//read mask
					if( mask )
					{
						if( socketBytes.bytesAvailable > 0 ) masks[0] = socketBytes.readUnsignedByte();
						if( socketBytes.bytesAvailable > 0 ) masks[1] = socketBytes.readUnsignedByte();
						if( socketBytes.bytesAvailable > 0 ) masks[2] = socketBytes.readUnsignedByte();
						if( socketBytes.bytesAvailable > 0 ) masks[3] = socketBytes.readUnsignedByte();
					}
					
					if( socketBytes.bytesAvailable > 0 )
					{
						var byteArray:ByteArray = new ByteArray(),
							j:uint = 0,
							k:uint = 0,
							previousLength:uint = 0;
						
						while( len > 0 )
						{
							socketBytes.readBytes(byteArray, j, Math.min(len, uint.MAX_VALUE));
							k = byteArray.length - previousLength;
							j += k;
							len -= k;
							previousLength = byteArray.length;
						}
						if( mask )
						{
							for( var i:uint = 0; i < byteArray.length; ++i )
							{
								byteArray[ i ] = (byteArray[ i ] ^ masks[ i % 4 ] );
							}
						}
						
						byteArray.position = 0;
						while( byteArray.bytesAvailable > 0 )
						{
							var byte:int = byteArray.readUnsignedByte();
							switch( byte )
							{
								default:
									messageString += String.fromCharCode( byte );
									break;
							}
						}
					}
				}
			}
			WebSocketMessager.getPurpose( messageString, this.webSocket );
			
			return messageString;
		}
	// end
	}
}