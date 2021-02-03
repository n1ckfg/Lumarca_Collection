// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/LumarcaShader" {
Properties {
	[MaterialToggle] _Spin("Spinning?", Float) = 0
	_NearClippingPlan ("Near Clipping Plane", float) = 1024
	_CameraPos ("CameraPos", Vector) = (1,0,0,0)
	_Tolerance ("Tolerance", float) = 10
	_Center ("Center", Vector) = (0, 0, 0, 0)
    _Texture1 ("Texture 1", 2D) = "white" { }
    _Texture2 ("Texture 2", 2D) = "white" { }
	_TextureWidth ("Texture Width", int) = 1024
	_TextureHeight ("Texture Height", int) = 768
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
	
//			uniform vec4 _Time; // model matrix
	
			float _Spin;
			float _Tolerance;
			float _NearClippingPlan;
			float4 _CameraPos;
			float4 _Center;
			sampler2D _Texture1;
			sampler2D _Texture2;
			int _TextureWidth;
			int _TextureHeight;
	 
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
                float4 scrPos;
			};
			
			float PartsToFloat(float i1, float i2){
				float f = i1 * 10000;
				f += i2 * 100;

				return f;
			} 
			 

         vertexOutput vert(vertexInput input) 
         {
            vertexOutput output; 
 
            output.pos =  mul(UNITY_MATRIX_MVP, input.vertex);
            output.position_in_world_space = 
               mul(unity_ObjectToWorld, input.vertex);
               
            output.scrPos = ComputeScreenPos(output.pos);
               // transformation of input.vertex from object 
               // coordinates to world coordinates;
            return output;
         }
         
         fixed4 frag2(vertexOutput i) : COLOR {
         
         	float4 ray = i.position_in_world_space - _CameraPos;
         	
         	float dist = distance(_CameraPos, ray);
         	
         	ray = ray/dist; //normalize(ray);
         
         	float4 point = ray * dist;
         
         	float2 wcoord = float2((point.x)/_TextureWidth - 0.5, (point.y)/_TextureHeight);
         	
            float4 color = tex2D(_Texture2, wcoord);

            return color;
         }
 
         float4 frag(vertexOutput input) : COLOR 
         {
         	
         	float4 result = float4(0, 0, 0, 0);
         	
         	float4 ray = input.position_in_world_space - _CameraPos;
         	
         	float dist = distance(_CameraPos, ray);
         	
         	ray = ray/dist; //normalize(ray);
         
         	float4 point = ray * dist;
         
         	float2 coord = float2((point.x)/_TextureWidth - 0.5f, (point.y)/_TextureHeight);
         	
         	if(_Spin){
         		float2 center = float2(_TextureWidth/2, _TextureHeight/2);
         		float2 spinPos = float2(coord.x - center.x, coord.y - center.y);
         		
         		float spinMag = distance(center, spinPos);
         		
         		coord = float2(center.x + sin(_Time.w/1.0) * spinMag, center.y + cos(_Time.w/1.0) * spinMag);
         	}
         	
         	float4 pixelCol = tex2D(_Texture1, coord);
         	float4 pixelCol2 = tex2D(_Texture2, coord);
         	
         	float x = PartsToFloat(pixelCol.r, pixelCol2.r);
         	float y = PartsToFloat(pixelCol.g, pixelCol2.g);
         	float z = PartsToFloat(pixelCol.b, pixelCol2.b);
         	
         	
         	if(coord.x < -0.5f){
         		x = -x;
         	}
         	
         	float4 pos = float4(x, y, z, input.position_in_world_space.w);
         	
         	if(pixelCol.r + pixelCol.g + pixelCol.b != 0){
         		if(abs(input.position_in_world_space.z - pos.z) < _Tolerance){
         			result = float4(1, 0, 0, 1);//pixelCol2;
         			
         			if(_Spin){
//         				result.y = 1;
         			}
         		}
         	}
         	
         	
			return result; 
         }
         
		ENDCG
	    }
	}

//Fallback "VertexLit"
} 