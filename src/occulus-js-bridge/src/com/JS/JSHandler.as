package com.JS
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.LocationChangeEvent;
	import flash.media.StageWebView;

	/**
	 * Acts as a bridge between actionscript and
	 * javascript that runs in a StageWebView
	 **/
   public class JSHandler
   {
	  public var webView:StageWebView;
	  
	  private var interfaceReady:Array = [];
	  
	  private var messageString:String = "";
	  private var messageStrLen:int = 0;
	  
	  /**
	   * Cosntructor JSHandler
	   * @param StageWebView
	   * 
	   * Accepts a stageWebView (browser instance)
	   * as its sole argument and creates a bridge between AIR and 
	   * that browser
	   **/
	  public function JSHandler( arg:StageWebView )
	  {
		this.webView = arg;
		
		arg.addEventListener( Event.COMPLETE, ExternalInterface );
		arg.addEventListener( ErrorEvent.ERROR, ExternalInterface );
		arg.addEventListener( FocusEvent.FOCUS_IN, ExternalInterface );  
		arg.addEventListener( FocusEvent.FOCUS_OUT, ExternalInterface );
		arg.addEventListener( LocationChangeEvent.LOCATION_CHANGE, ExternalInterface );
		arg.addEventListener( LocationChangeEvent.LOCATION_CHANGING, ExternalInterface );

		this.messageString = "data://";
		this.messageStrLen = this.messageString.length;
	  }
	  
	  /**
	   * Calls JavaScript function
	   **/
	  public function call( func:String = "alert(1);") : void
	  {
		  this.webView.loadURL( "javascript:" + func );
	  }
	  /**
	   * Adds a listener for a function called through javascript,
	   * and calls the "func" argument when that specific function is called
	   **/
	  public function listen( name:String, func:Function ) : void
	  {
		  	if( !this.interfaceReady[name] )
			     this.interfaceReady[name] = func;
			else
			{
				this.interfaceReady[name] = null;
				this.interfaceReady[name] = func;
			}
	  }
	  
	  /**
	  * Removes JS listener of FLEX
	  **/
	  public function unlisten( name:String, func:Function ) : void
	  {
		  this.interfaceReady[name] = null;
	  }
	  /**
	   * Listens for URL change / Javascript Functions 
	   * and acts accordingly
	   **/
	  private function ExternalInterface( e:Event ) : void
	  {
		  if( e.type == "locationChanging" )
		  {
				  var currLocation:String = unescape((e as LocationChangeEvent).location);

				  var tagIndex:int = currLocation.indexOf( this.messageString ) + this.messageStrLen;

				  if( tagIndex >= this.messageStrLen )
				  {
					  e.preventDefault();
					  currLocation = currLocation.substr( tagIndex );
					  
					  var functionArray:Array = currLocation.split('}{');
					  var functionArrayLength:int = functionArray.length;
					 
					  var name:Array;
					  var args:Array = [];
					  
					  var tmpArr:Array = [ null, null ];
					  var whileInt:int = 0;
					  
					  //default Arguments - main plug in
					  //These arguments are always [ 0 ] -> path and [ 1 ] -> name
					  name = functionArray[ 0 ].split('?~=');
					  if( name[ 0 ] == "CORE" ) {
						tmpArr = name[ 1 ].split(',');
						whileInt = 1;
					  }
					  
					  while( functionArrayLength-- > whileInt )
					  {
						  name = functionArray[ functionArrayLength ].split('?~=');
						  if( name.length > 1 )
						  {
							args = name[ 1 ].split(',');
							args['path'] = trimWhitespace( tmpArr[ 0 ] );
							args['name'] = trimWhitespace( tmpArr[ 1 ] );
						  }
						  else
						  {
							args = [];
							args['path'] = trimWhitespace( tmpArr[ 0 ] );
							args['name'] = trimWhitespace( tmpArr[ 1 ] );
						  }
						  if( this.interfaceReady[ name[ 0 ] ] )
						      this.interfaceReady[ name[ 0 ] ].call( this, args );
					  }
				  }
		  }
	  }
	  
	  // UTILS
	  // trims all whitespaces
	  private function trim( str:String ) : String
	  {
		  for( var i:int = 0; str.charCodeAt( i ) < 33; i++ ){}
		  for( var j:int = str.length - 1; str.charCodeAt( j ) < 33; j-- ){}
		  
		  return str.substring( i, j + 1 );
	  }
	  // Trims preceeding whitespace
	  private function trimWhitespace( $string:String ) : String
	  {
		  if( $string == null )
			  return "";
		  
		  return $string.replace( /^\s+|\s+$/g, "" );
	  }
	  // end
   }
}