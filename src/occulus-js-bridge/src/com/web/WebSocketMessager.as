package com.web
{
	import com.web.WebSocket;
	import com.web.config.GlobalModel;
	
	public final class WebSocketMessager
	{
		public var webSocket:WebSocket = null;
		
		public function WebSocketMessager() {}
		
		/**
		 *	Check to see what the websocket wants (separated in configuration info and other (any) kind of data 
		 * 
		 * @param	str	-	String received
		 * @param	socket	-	socket from where the request came, this can be null
		 **/
		public static function getPurpose( str:String, webSocket:WebSocket = null ) : void
		{
			// if the first character is ~ then we are speaking about configuration
			// if the first two characters are ~| then multiple configuration paths have been sent, check 
			// Since there won't be many configuration objects passed, an extra character should not be an issue
			// so we should keep "bare" messages for common cases
			// implement all of them, and answer to the client
			var firstChar:String = str.charAt( 0 );

			trace( "recv: " + str );

			//configuration
			if( firstChar === '~' )
			{
				str = str.substr( 1 );
				if( str.charAt( 0 ) == '|' )	//multiple configuration object found
				{
					str = str.substr( 1 );
					
					var temp_array:Array = str.split('}{'),
						len:int = temp_array.length;
					
					while( len-- > 0 )
						_configuration( temp_array[ len ], webSocket );
					
					webSocket.sendMessage( "_.CONFIGCOMPLETE()", 18 );
				}
				else
					_configuration( str, webSocket );
			}
			else
			{
				//TODO: other stuff here --- actions for controllers etc
			}
		}

		/**
		 *	Check to see what the websocket wants (separated in configuration info and other (any) kind of data 
		 * 
		 * @param	str	-	String received
		 * @param	socket	-	socket from where the request came, this can be null
		 **/
		private static function _configuration( str:String, webSocket:WebSocket = null ) : void
		{
			var firstChar:String = str.charAt( 0 );
			switch( firstChar ) {
				case ( "C" ) :	//number of players required --> P2 for two players
					GlobalModel.getInstance().fireEvent("calibrateDevice");
					break;
				case ( "D" ) :	//number of players required --> P2 for two players
					GlobalModel.getInstance().fireEvent("clearCalibrateDevice");
					break;
				case ( "K" ) :
					if( str == "KILL" )
					{
						GlobalModel.getInstance().fireEvent("BangBangWeReDead");
						return ;
					}
					break;
			}
		/*	switch( firstChar ) {
				case ( "P" ) :	//number of players required --> P2 for two players
					GlobalModel.getInstance().max_skeletons = parseInt( str.substr( 1 ) );
					break;
				case ( "G" ) :	//gestures tracked --> [ JUMP, SWIPE, THRUST, ESCAPE ]
					str = str.substr( 1, str.length );
					if( str.indexOf('-') !== -1 )
						GlobalModel.getInstance().gestures = str.split('-');
					else
					{
						GlobalModel.getInstance().gestures = [];
						GlobalModel.getInstance().gestures[ 0 ] = str;
					}
					break;
				case ( "H" ) :
					//H_ get current angle
					if( str == "H" ) {}
						//GlobalModel.getInstance().kinectPostMessage( "scan_head" );
					else if( str == "H_" ) {
						var tmpStr:String = '_.MOTOR(' + GlobalModel.getInstance().kinect.cameraElevationAngle + ')';
						webSocket.sendMessage( tmpStr, tmpStr.length );
					}
					else {
						str = str.substr( 2 ); // doesn't work?
						GlobalModel.getInstance().kinect.cameraElevationAngle = parseInt( str );
					}
					break;
				case ( "S" ) :
					GlobalModel.getInstance().kinect.setSkeletonSmoothing( parseFloat( str.substr( 1 ) ) - 1.0 );
					break;
				case ( "K" ) :
					if( str == "KILL" )
					{
						if( webSocket )
							webSocket.terminate();
						return ;
					}
					break;
				case ( "-" ) :
				// default:
					// R == RAW
					// D == DEPTH
					// Q == WORLD PERCENT
					// W == WORLD CENTIMETERS
					// A == REL PERCENT
					// S == REL CENTIMETERS
					// Z == ROTATIONS
					
					// default read joints data sample, -R11,3-A7,17
					// which means, RAW [ 11, 3 ]  REL PERCENT [ 7, 17 ]
					
					if( str.indexOf('-') !== -1 )
					{
						var arr:Array = str.split('-'),
							first_char:String = "",
							rest_str:String = "",
							sub_arr:Array = [];

						arr.shift();
						
						GlobalModel.getInstance().skeleton_struct.resetAll();
						for( var i:int = 0; i < arr.length; ++i ) {
							// check the first char
							first_char = arr[ i ].charAt( 0 );
							rest_str = arr[ i ].substr( 1, arr[ i ].length );
							
							if( rest_str === "" )
								continue;

							sub_arr = rest_str.split(",");
							
							switch( first_char ) {
								case ( "R" ) :
									GlobalModel.getInstance().skeleton_struct.raw = sub_arr;
									break;
								case ( "D" ) :
									GlobalModel.getInstance().skeleton_struct.depth = sub_arr;
									break;
								case ( "Q" ) :
									GlobalModel.getInstance().skeleton_struct.world_percent = sub_arr;
									break;
								case ( "W" ) :
									GlobalModel.getInstance().skeleton_struct.world_meters = sub_arr;
									break;
								case ( "A" ) :
									GlobalModel.getInstance().skeleton_struct.rel_percent = sub_arr;
									break;
								case ( "S" ) :
									GlobalModel.getInstance().skeleton_struct.rel_meters = sub_arr;
									break;
								case ( "Z" ) :
									GlobalModel.getInstance().skeleton_struct.rot = sub_arr;
									break;
							}
						}
					}
					else
					{
						// empty message received, reset the whole structure
						GlobalModel.getInstance().skeleton_struct.resetAll();
						GlobalModel.getInstance().skeleton_struct.world_percent = [ '11' ];
					}
					break;
			}
			*/
		}
	// end
	}
}