package com.web
{
	public final class WebSocketOpcode
	{
		// non-control opcodes		
		public static const CONTINUATION:int = 0x00;
		public static const TEXT_FRAME:int = 0x01;
		public static const TEXT_FRAME_SINGLE:int = 0x81;
		public static const BINARY_FRAME:int = 0x02;
		public static const BINARY_FRAME_SINGLE1:int = 0x82;
		public static const BINARY_FRAME_SINGLE2:int = 0x7E;
		public static const BINARY_FRAME_256:int = 0x0100;
		public static const BINARY_FRAME_64k:int = 0x0000000000010000;
		// 0x03 - 0x07 = Reserved for further control frames
		
		// Control opcodes 
		public static const CONNECTION_CLOSE:int = 0x08;
		public static const PING:int = 0x09;
		public static const PONG:int = 0x0A;
		// 0x0B - 0x0F = Reserved for further control frames
	}
}