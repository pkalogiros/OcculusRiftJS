/**
* author: pkalogiros (pkalogiros [at] live.com)
* date 23/09/2013
*
* description : ...
**/

(function( w ) {
  "use strict";

  w.rift = {
    _version       : 1.0,
    _defaultport   : 9123,
    _latestAttempt : 0,

    eulerAngle    : { x : 0, y : 0, z : 0, order : "XYZ" },
    quaternion    : { x : 0, y : 0, z : 0, w : 1.0 },

    setEulerFromQuaternion : function( order ) {
      function clamp( x ) {
        return Math.min( Math.max( x, -1 ), 1 );
      }
      var q = w.rift.quaternion;
      var eul = w.rift.eulerAngle;

      var sqx = q.x * q.x;
      var sqy = q.y * q.y;
      var sqz = q.z * q.z;
      var sqw = q.w * q.w;

      order = order || eul.order;

      if ( order === 'XYZ' ) {
        eul.x = Math.atan2( 2 * ( q.x * q.w - q.y * q.z ), ( sqw - sqx - sqy + sqz ) );
        eul.y = Math.asin(  clamp( 2 * ( q.x * q.z + q.y * q.w ) ) );
        eul.z = Math.atan2( 2 * ( q.z * q.w - q.x * q.y ), ( sqw + sqx - sqy - sqz ) );
      } else if ( order ===  'YXZ' ) {
        eul.x = Math.asin(  clamp( 2 * ( q.x * q.w - q.y * q.z ) ) );
        eul.y = Math.atan2( 2 * ( q.x * q.z + q.y * q.w ), ( sqw - sqx - sqy + sqz ) );
        eul.z = Math.atan2( 2 * ( q.x * q.y + q.z * q.w ), ( sqw - sqx + sqy - sqz ) );
      } else if ( order === 'ZXY' ) {
        eul.x = Math.asin(  clamp( 2 * ( q.x * q.w + q.y * q.z ) ) );
        eul.y = Math.atan2( 2 * ( q.y * q.w - q.z * q.x ), ( sqw - sqx - sqy + sqz ) );
        eul.z = Math.atan2( 2 * ( q.z * q.w - q.x * q.y ), ( sqw - sqx + sqy - sqz ) );
      } else if ( order === 'ZYX' ) {
        eul.x = Math.atan2( 2 * ( q.x * q.w + q.z * q.y ), ( sqw - sqx - sqy + sqz ) );
        eul.y = Math.asin(  clamp( 2 * ( q.y * q.w - q.x * q.z ) ) );
        eul.z = Math.atan2( 2 * ( q.x * q.y + q.z * q.w ), ( sqw + sqx - sqy - sqz ) );
      } else if ( order === 'YZX' ) {
        eul.x = Math.atan2( 2 * ( q.x * q.w - q.z * q.y ), ( sqw - sqx + sqy - sqz ) );
        eul.y = Math.atan2( 2 * ( q.y * q.w - q.x * q.z ), ( sqw + sqx - sqy - sqz ) );
        eul.z = Math.asin(  clamp( 2 * ( q.x * q.y + q.z * q.w ) ) );
      } else if ( order === 'XZY' ) {
        eul.x = Math.atan2( 2 * ( q.x * q.w + q.y * q.z ), ( sqw - sqx + sqy - sqz ) );
        eul.y = Math.atan2( 2 * ( q.x * q.z + q.y * q.w ), ( sqw + sqx - sqy - sqz ) );
        eul.z = Math.asin(  clamp( 2 * ( q.z * q.w - q.x * q.y ) ) );
      }

      eul.order = order;
      return (eul);
    },
    
    calibrate : function() {
      if( !this.connected ) {
        console.log( "cannot calibrate without connection" );
        return (this);
      }
      this.socket.send("~C");
      
      return (this);
    },
    
    clearCalibration : function() {
      if( !this.connected ) {
        console.log( "cannot calibrate without connection" );
        return (this);
      }
      this.socket.send("~D");
      
      return (this);
    },
    
    killServer : function() {
      if( !this.connected ) {
        console.log( "cannot kill the non-existent server duh..." );
        return (this);
      }
      this.socket.send("~KILL");
    },
    
    socket : null,
    connected : false,
    connect : function( address ) {
      var q = this;
      
      if( !address )
        address = this._defaultport;
      
      address = address.replace("ws://", "");

      if( address[0] && address[0] === ":" )
        address = address.substring(1);
      
      this._latestAttempt = address;
      
      if( address.length <= 5 )
        address = "localhost:" + address;
      
      q.socket = new WebSocket( "ws://" + address );
      
      q.socket.onopen = function(evt) {
        console.log( evt );
        q.connected = true;
        q.fireEvent( "socketOpened", evt );
      };
      q.socket.onclose = function(evt) {
        console.log( evt );
        q.connected = false;
        q.fireEvent( "socketClosed", evt );
      };
      q.socket.onmessage = function(evt) {
        var arr = eval(evt.data);
        
        q.quaternion.x =  arr[0];
        q.quaternion.y =  arr[1];
        q.quaternion.z =  arr[2];
        q.quaternion.w =  arr[3];

        q.onMessage( q.quaternion );
      };
      q.socket.onerror = function(evt) {
        console.log( evt );
        q.connected = false;
        q.fireEvent( "socketError", evt );
      };
    },
    __SINK : {},
    addEventListener : function( event, callback, isFirst ) {
      if( !this.__SINK[event] )
        this.__SINK[event] = [];
        
      if( isFirst )
        this.__SINK[event].push( callback );
      else
        this.__SINK[event].unshift( callback );
        
      return (callback);
    },
    removeEventListener : function( event, callback, persist ) {
      var e, i;
      if( e = this.__SINK[event] ) {
        i = e.length;
        while( i-- ) {
          if( e[i] === callback )
            e[i] = null;
            
          if( persist )
            break;
        }
      }
    },
    removeListenerByIndex : function( event, index ) {
      var e;
      if( e = this.__SINK[event] ) {
        if( e[index] )
          e[index] = null;
      }
    },
    removeAll : function( event ) {
      this.__SINK[event] = [];
    },
    disconect : function() {
      if( socket )
        socket.close();
      return (this);
    },
    getSocket : function() {
      return (this.socket);
    },
    fireEvent : function( eventName, args ) {
      var e, i;
      if( e = this.__SINK[eventName] ) {
        i = e.length;
        while( i-- )
          e[i] && e[i]( args );
      }
    },
    onMessage : function( msg ) {}
  };
  // end
})( this );