package com.rift
{
	import com.web.WebSocketServer;
	
	import flash.events.Event;
	
	import oculusANE.OculusANE;
	
	public class RiftBridge
	{
		private var _rift:OculusANE;
		private var _wserver:WebSocketServer;
		private var _parent:Object;
		private var _SINK:Object;
		private var _deviceInfo:Object;
		
		private var _pres:int = 11;
		
		private var calibrationQuat:Vector.<Number>;
		private var latestQuat:Vector.<Number>;
		
		/** constructor **/
		public function RiftBridge( app:Object )
		{
			this._parent = app;
			this._SINK = {};
			
			latestQuat = new Vector.<Number>;
			calibrationQuat = new Vector.<Number>;
			calibrationQuat[0] = 0;
			calibrationQuat[1] = 0;
			calibrationQuat[2] = 0;
			calibrationQuat[3] = 1;
		}
		
		/** Destroyes the Rift extension and the web socket server **/
		public function dispose() : void
		{
			this._parent.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			this._wserver.close();
			this._rift.dispose();
		}
		
		/** resets the websocket server **/
		public function resetServer() : void
		{
			this._wserver.reset();
			this.fireEvent("serverReady", [ this._wserver.IPCONFIG ] );
		}

		/** halts the rift device **/
		public function stopRift() : void
		{
			this._parent.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			if( this._rift )
				this._rift.dispose();
		}
		
		/** kickstarts the websocket server **/
		public function startServer() : void
		{
			this._wserver = new WebSocketServer();
			this.fireEvent("serverReady", [ this._wserver.IPCONFIG ] );
		}
		
		/** kickstarts the occulus rift device **/
		public function startOcculus() : Boolean
		{
			this._parent.removeEventListener(Event.ENTER_FRAME, handleEnterFrame);
			if( this._rift )
				this._rift.dispose();

			this._rift = new OculusANE();

			if (this._rift.isSupported()) {
				this._parent.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
				_deviceInfo = _rift.getHMDInfo();
				
				return (true);
			} else
				trace("Oculus Rift not connected or unsupported.");

			return (false);
		}
		
		/** @return object **/
		public function getDeviceInfo():Object
		{
			return (this._deviceInfo);
		}
		
		// Quaternion helper functions
		private function conjugateQuat( quat:Vector.<Number> ) : Vector.<Number>
		{
			quat[0] *=-1;
			quat[1] *=-1;
			quat[2] *=-1;
			return (quat);
		}

		private function normaliseQuat( quat:Vector.<Number> ) : Vector.<Number>
		{
			var a:Number = Math.sqrt( quat[0] * quat[0] + quat[1] * quat[1] + quat[2] * quat[2] + quat[3] * quat[3] );
			
			if( a === 0) {
				quat[0] = quat[1] = quat[2] = 0;
				quat[3] = 1;
			}
			else {
				a = 1 / a;
				quat[0] *= a;
				quat[1] *= a;
				quat[2] *= a;
				quat[3] *= a;
			}
				
			return (quat);
		}
		private function inverseQuat( quat:Vector.<Number> ) : Vector.<Number>
		{
			quat = this.conjugateQuat( quat );
			quat = this.normaliseQuat( quat );
			return (quat);
		}
		
		public function calibrate() : void
		{
			calibrationQuat[0] = latestQuat[0];
			calibrationQuat[1] = latestQuat[1];
			calibrationQuat[2] = latestQuat[2];
			calibrationQuat[3] = latestQuat[3];
			
			calibrationQuat = inverseQuat(calibrationQuat);
		}
		
		public function clearCalibration() : void
		{
			calibrationQuat[0] = 0;
			calibrationQuat[1] = 0;
			calibrationQuat[2] = 0;
			calibrationQuat[3] = 1.0;
		}
		
		private function handleEnterFrame(event:Event) : void
		{
			var vec:Vector.<Number> = _rift.getCameraQuaternion();
			latestQuat[0] = vec[0];
			latestQuat[1] = vec[1];
			latestQuat[2] = vec[2];
			latestQuat[3] = vec[3];
			
			trace("Vec: " + vec[0] + "/" + vec[1] + "/" + vec[2] + "/" + vec[3]);
			
			// multiply quaternions 
			var h:Number = calibrationQuat[0],
				g:Number = calibrationQuat[1],
				i:Number = calibrationQuat[2],
				k:Number = calibrationQuat[3],
				
				c:Number = vec[0],
				d:Number = vec[1],
				e:Number = vec[2],
				f:Number = vec[3];
			
			vec[0] = c * k + f * h + d * i - e * g;
			vec[1] = d * k + f * g + e * h - c * i;
			vec[2] = e * k + f * i + c * g - d * h;
			vec[3] = f * k - c * h - d * g - e * i;
			
			var strSend:String = "[" + vec[0].toPrecision(_pres) + "," + vec[1].toPrecision(_pres) + "," + vec[2].toPrecision(_pres) + "," + vec[3].toPrecision(_pres) + "]";
			this._wserver.broadCast( strSend );
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
		// end
	}
}