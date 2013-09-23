package com.web.config
{
	import com.web.WebSocketServer;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
	 * GlobalModel
	 * 
	 * Acts as a storage between the WebSocketServer and the KinectJS classes
	 * contains info on the data sent to the browser
	 **/
	public class GlobalModel
	{
		
		public var WServer:WebSocketServer;
		
		/** singleton pattern **/
		private static var _self:GlobalModel;	// singleton
		/** hidden sink object to hold the event callbacks **/
		protected var _SINK:Object = {};
		/** Singleton Constructor **/
		public function GlobalModel()
		{
			_self = this;
		}
		
		public function resetAllEvents() : void
		{
			_SINK = {};
		}
		
		/** @return GlobalModel **/
		public static function getInstance() : GlobalModel
		{
			if( !_self )
				 _self = new GlobalModel();

			return _self; 
		}
		
		/**
		 *	Mimics Javascript's addEventListener method
		 * 
		 *	@param	String name of the event
		 *	@param	Function callback of the event
		 *	@param	Boolean if set to false, then the callback will be the last to fire
		 **/
		public function addEventListener( event:String, args:Function, first:Boolean = true ) : void
		{
			if( !_SINK[ event ] )
				 _SINK[ event ] = new Array();
			
			if( first )
				_SINK[ event ].push( args );
			else
				_SINK[ event ].unshift( args );
		}
		
		/**
		 *	Simulates remove event listener as in the JS api
		 *
		 *	@return	Boolean	false for not finding any function, and true for removing something
		 * 
		 *	@param	String	event name
		 *	@param	Function	function to find and unbind 
		 **/
		public function removeEventListener( event:String, callback:Function ) : Boolean
		{
			var len:int;
			if( _SINK[ event ] && ( len = _SINK[ event ].length ) )
			{
				var removed:Boolean  = false;
				
				while( len-- > 0 )
					if( _SINK[ event ][ len ] == callback )
					{
						_SINK[ event ][ len ] = null;
						removed = true;
					}
				
				if( removed )
					return true;
			}
			return false;
		}
		/**
		 * Removes all listeners for a given event
		 * @param String event
		 * @return void
		 **/
		public function removeAllListeners( event:String ) : void
		{
			if( _SINK[ event ] )
				_SINK[ event ] = new Array();
		}
		
		/** 
		 * Simulates event firing (same as the JS Handler )
		 * 
		 * @param	String name of the event
		 * @param	Array  Array of arguments
		 **/
		public function fireEvent( event:String, args:Array = null ) : void
		{
			var func_arr:Array = _SINK[ event ];
			
			if( func_arr != null )
			{
				var len:int = func_arr.length;
				while(  len-- > 0 )
					func_arr[ len ]( args );
			}
		}
		
		/**
		 * Javascript like setTimeout, function
		 * 
		 * @param callback	function to be called on timeout
		 * @param interval	(milliseconds) timeout duration
		 * @param count	how many times will the timeout run? (default is 1)
		 **/
		public function setTimeout( callback:Function, interval:int, count:int = 1 ) : Timer
		{
			var timer:Timer = new Timer( interval, count );
			timer.addEventListener( TimerEvent.TIMER_COMPLETE, function( e:TimerEvent ) : void { callback() } );
			timer.start();
			
			return timer;
		}
	// end
	}
}