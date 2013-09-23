package com.web
{
	import com.web.config.GlobalModel;
	import com.web.draft.Draft_10;
	import com.web.draft.Draft_17;
	import com.web.draft.Draft_Old;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	/**
	 * Handles the messaging between AS and JS
	 * in its core - it a simple socket server that accepts connections - saves the sockets in arrays 
	 * broadcasts messages to those sockets - and writes data to the GlobalModel singleton
	 * (for use in the other parts of the app)
	 **/
	public class WebSocketServer
	{
		/** String to be written in the app's textarea - contains all available addresses **/
		public var IPCONFIG:String = "";
		
		/** socket server instance (listens for connections) **/
		private var v:ServerSocket;
		
		/** available sockets ::
		 * 	- [0] Skeleton info
		 *	- [1] Depth
		 *  - [2] RGB data 
		 *  - [3] External interfaces/devices
		 * **/
		public var socket_array:Array = [ [],  [], [], [] ];
		private var attempts:int = 0;
		
		/** listening to this port ( random number greater than 8200 actually) **/
		private var port:int;
		
		/**
		 * WebSocketServer - Constructor
		 **/
		public function WebSocketServer()
		{
			this.port = 9123; //(( Math.random() * 1798 ) >> 0 ) + 8200;
			GlobalModel.getInstance().WServer = this;

			findInterface();		// finds available addresses

			v = new ServerSocket();	// initializes socket server
			listen( port );			// starts listening
		}
		
		/**
		 * @return int
		 * Returns the port
		 **/
		public function getPort() : int
		{
			return this.port;
		}
		
		/**
		 * listen( int ) (protected)
		 * @void
		 * @param port:int - listen to this port, or trace error message on fail
		 **/
		protected function listen( port:int ) : void
		{
			try
			{
				v.addEventListener( Event.CONNECT, socketConnectHandler );
				v.bind( port );
				v.listen();
				
				attempts = 0;
				trace("Listening on port " + port + "...\n");
			}
			catch (error:Error)
			{
				++attempts;
				trace("Port " + port + " may be in use. \n(" + error.message + ")", "Error");
				
				if( attempts < 5 ) {
					listen( (( Math.random() * 1798 ) >> 0 ) + 8200 );
				}
				else {
					trace("SERVER ERROR SOS!!!");
					GlobalModel.getInstance().fireEvent("serverError");
				}
			}
		}
		
		/**
		 * socketConnectHandler( int ) (protected)
		 * Runs on connection and adds the socket in the socket_array, binds events to it
		 * 
		 * @param event:ServerSocketConnectEvent - dispathced automatically
		 **/
		protected function socketConnectHandler( event:ServerSocketConnectEvent ) : void
		{
			var socket:Socket = event.socket;
			
			socket.addEventListener( ProgressEvent.SOCKET_DATA, socketDataHandler );
			socket.addEventListener( Event.CLOSE, _onClose );
		}
		/**
		 * socketDataHandler( int ) (protected)
		 * Runs when we server receives data - checks and performs the handshake
		 * or sets data to the GlobalModel
		 * 
		 * @param event:ProgressEvent - dispathced automatically
		 **/
		public function socketDataHandler( event:ProgressEvent ):void
		{
				//checking to see 
			var socket:Socket = event.target as Socket,
				str:String = "",
				bytes:ByteArray = new ByteArray();
			
			socket.readBytes( bytes );
			str += bytes;
			
			if( str.indexOf( "WebSocket") !== -1 ) // supports Chrome, Opera, Firefox, IE, Safari
			{
				var socket_type:int = 0;
				//client asked for depth data
				if( str.indexOf( "__depth" ) !== -1 )
					socket_type = 1;
				//client asked for rgb data
				else if( str.indexOf( "__rgb") !== -1 )
					socket_type = 2;
				
				/** check for websockets **/
				if( str.indexOf( "Sec-WebSocket-Version: 13") !== -1 )
					// read websocket v13 (chrome) 
					socket_array[ socket_type ].push( new Draft_17().connection( socket, str, bytes, port ) );
				else if( str.indexOf( "Sec-WebSocket-Version: 8") !== -1 )
					// read websockt v8 (firefox)
					socket_array[ socket_type ].push( new Draft_10().connection( socket, str, bytes, port ) );
				else
					// ios, ie10, old opera
					socket_array[ socket_type ].push( new Draft_Old().connection( socket, str, bytes, port ) );
				
			//	if( socket_type === 2 )
			//		GlobalModel.getInstance().handler.frames.startRGB();
			//	else if( socket_type === 1 )
			//		GlobalModel.getInstance().handler.frames.startDepth();
				
				//securing that no socket will try to reconect
				socket.removeEventListener( ProgressEvent.SOCKET_DATA, socketDataHandler );
				return ;
			
			}
			else if( str.indexOf( "HTTP/1.1" ) !== -1 ) // normal http requests. Check to see if we are asking to be served an image - or save an image
			{
				str = str.substr( 4 );
				
				if( str.indexOf('button') !== -1  )
					buttonServer( str );
				else if( str.indexOf('image') !== -1 ) {
					if( str.indexOf('ge_0') !== -1 )
						imageServerB64( socket, 0 );
					else if( str.indexOf('ge_1') !== -1 )
						imageServerB64( socket, 1 );
					else if( str.indexOf('ge0') !== -1 )
						imageServer( socket, 0 );
					else if( str.indexOf('ge1') !== -1 )
						imageServer( socket, 1 );
				}
				socket.flush();
				socket.close();
			}
			else
			{
				//unknown socket type
				socket.flush();
				socket.close();
			}
		}
		/**
		 * Sends direct data to the KinectSocketServer
		 * which is then broadcasted to all of the clients
		 * 
		 * it cannot contain configuration info, only action and "hit-like"
		 * args
		 * 
		 * @param	str	- String that contains the request
		 **/
		private function buttonServer( str:String ) : void
		{
			var extra_args:Array = str.split('HTTP/1.1');
			var extra_str:String = extra_args[ 0 ];
			
			extra_args = extra_str.split('/?');
			extra_str = extra_args[ 1 ];
			
			broadCast( "_.FIRE('" + extra_str + "')", 0 );
		}
		/**
		 *	Regular HTTP post, answers with JS closure function that when evaluated reveals 
		 *  to be image data
		 * 
		 *  @param	socket - Socket to which the image will be sent
		 * 
		 * TODO: Currently there is a performance hit when this occurs, find a way to bypass it
		 * 		without having to store temporary images in the FileSysetm
		 **/
		private function imageServer( socket:Socket, type:uint ) : void
		{
			// make an image and answer the async request
			// 0 for depth, 1 for RGB
			// socket.writeUTFBytes("HTTP/1.1 200 OK\n");
			// socket.writeUTFBytes("Content-Type: image/jpeg\n\n");
			
			// socket.writeBytes( GlobalModel.getInstance().getImage( type ) );
		}
		private function imageServerB64( socket:Socket, type:uint ) : void
		{
			// make an image and answer the async request
			// 0 for depth, 1 for RGB
			// socket.writeUTFBytes("HTTP/1.1 200 OK\n");
			// socket.writeUTFBytes("Content-Type: text/plain\n\n");
			
			// socket.writeUTFBytes( "(function(){kinect.imageCommands.currentImageData='data:image/jpeg;base64," + 
			//	GlobalModel.getInstance().getImageB64( type ) + "';})()" );
		}
		/**
		 * _onClose( String, int ) (private)
		 * Runs on socket termination and removes the socket from the socket_array
		 * 
		 * @param event:Event - dispatched automatically
		 **/
		private function _onClose( event:Event, _socket:Socket = null ) : void
		{
			var socket:Socket = null,
				len:int,
				tmpArr:Array = [],
				j:int = 4,
				k:int = -1;

			if( event == null )
				socket = _socket;
			else
				socket = event.target as Socket;

			while( j-- >= 0 )
			{
				if( !socket_array[ j ] )
					return ;
				
				len = socket_array[ j ].length;
				
				while( len-- > 0 )
					if( socket_array[ j ][ len ].socket == socket )
					{
						k = j;
						break;
					}

				if( k !== -1 )
					break;
			}
			
			if( k === -1 )
				return;
			
			len = socket_array[ k ].length;
			while( len-- >= 0 )
				if( socket_array[ k ][ len ] && socket_array[ k ][ len ].socket != socket )
					tmpArr.unshift( socket_array[ k ][ len ] );
			
			socket_array[ k ] = tmpArr;
			
			if( tmpArr.length === 0 )
				GlobalModel.getInstance().fireEvent( "noSockets", [ k ] );
		}
		/**
		 * broadCast( String, int ) (public)
		 * Sends a message to all of the sockets of specified type
		 * 
		 * @param data:String - Message to send
		 **/
		public function broadCast( data:String, type:uint = 0 ) : void
		{
			var socket_length:int = socket_array[ type ].length;

			for( var i:int = 0; i < socket_length; ++i )
				socket_array[ type ][ i ].sendMessage( "(" + data + ")", 0 );
		}
		public function depthBroadCast( data:String ) : void
		{
			var socket_length:int = socket_array[ 1 ].length;
			
			for( var i:int = 0; i < socket_length; ++i )
				socket_array[ 1 ][ i ].sendMessage(  data, 1 );
		}
		public function rgbBroadCast( data:String ) : void
		{
			var socket_length:int = socket_array[ 2 ].length;
			
			for( var i:int = 0; i < socket_length; ++i )
				socket_array[ 2 ][ i ].sendMessage(  data, 2 );
		}
		public function depthBroadCastBytes( data:ByteArray ) :void
		{
			var socket_length:int = socket_array[ 1 ].length;
			
			for( var i:int = 0; i < socket_length; ++i )
				socket_array[ 1 ][ i ].sendBytes(  data );
		}
		public function rgbBroadCastBytes( data:ByteArray ) : void
		{
			var socket_length:int = socket_array[ 2 ].length;
			
			for( var i:int = 0; i < socket_length; ++i )
				socket_array[ 2 ][ i ].sendBytes(  data );
		}
		
		/**
		 * reset() (public)
		 * Resets the socket server, and re-binds it to the (next)
		 * port + 1, port.
		 **/
		public function reset() : void
		{
			//v.close();
			v = null;
			
			++port;
			findInterface();
			
			v = new ServerSocket();
			listen( port );
		}
		
		/**
		 * Closes the SocketServer 
		 **/
		public function close() : void
		{
			if( v.listening )
				v.close();
			
			socket_array = [ [],  [], [], [] ];
		}
		
		/**
		 * findInterface() (public)
		 * Finds available interfaces (addresses) and creates/edits
		 * the IPCONFIG public string var
		 **/
		public function findInterface():void
		{
			var results:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces(),
				output:String = "Display Name:\nlocalhost:" + port + "\n\n",
				found:Boolean = false;
			
			for (var i:int=0; i < results.length; ++i)
			{
				output = output + results[i].displayName + "\n";
				
				for (var j:int = 0; j < results[ i ].addresses.length; ++j )
				{
					output = output
						+ "Address: " + results[i].addresses[j].address + ":" + port + "\n\n";
					
					if( results[i].addresses[j].prefixLength === 24 && results[i].active === true )
					{
						IPCONFIG += output + "\n";
						found = true;
					}
				}
			}

			if( !found )
				IPCONFIG += "Display Name:\nlocalhost:" + port + "\n\n";
		}
	// end
	}
}