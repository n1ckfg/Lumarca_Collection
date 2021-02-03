﻿Shader "Custom/ColorLerpShader"
{
Properties {
    _LerpPer ("Lerp Per", Float) = 0.5
    _Color1("Color 1", Color) = (0, 1, 0)
    _Color2("Color 2", Color) = (0, 1, 0)
}


SubShader {
 
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 200
    Blend SrcAlpha OneMinusSrcAlpha
    ZTest Less
 
    Pass {
  
            Cull Off
		CGPROGRAM
			// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members srcPos)
			#pragma exclude_renderers d3d11 xbox360
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"

			float _LerpPer;
			float4 _Color1;
			float4 _Color2;
	 
			struct v2f {
			    float4  pos : SV_POSITION;
			    float2  uv : TEXCOORD0;
			    float4 srcPos;
			};
			
			struct vertexInput {
				float4 vertex : POSITION;
			};
			struct vertexOutput {
				float4 pos : SV_POSITION;
				float4 position_in_world_space : TEXCOORD0;
			};
			
	         vertexOutput vert(vertexInput input) 
	         {
	            vertexOutput output; 
	 
	            output.pos =  mul(UNITY_MATRIX_MVP, input.vertex);
	            output.position_in_world_space = 
	               mul(unity_ObjectToWorld, input.vertex);
	               // transformation of input.vertex from object 
	               // coordinates to world coordinates;
	            return output;
	         }
 
	         float4 frag(vertexOutput input) : COLOR 
	         {
//	         	return _Color1;
	         	return lerp(_Color1, _Color2, _LerpPer);
	         }
         
		ENDCG
	    }
	}

//Fallback "VertexLit"
} 