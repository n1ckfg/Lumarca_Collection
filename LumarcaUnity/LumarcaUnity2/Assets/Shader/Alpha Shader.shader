Shader "game/Alpha Mask" {
Properties {
    _Vector1 ("Point1", Vector) = (1,0,0,0)
    _MainTex ("Texture", 2D) = "white" { }
}
SubShader {
 
    Tags { "RenderType"="Transparent" "Queue"="Transparent" }
    LOD 200
    Blend SrcAlpha OneMinusSrcAlpha
    ZTest Less
 
    Pass {
 
CGPROGRAM
// Upgrade NOTE: excluded shader from DX11 and Xbox360; has structs without semantics (struct v2f members srcPos)
#pragma exclude_renderers d3d11 xbox360
#pragma vertex vert
#pragma fragment frag
 
#include "UnityCG.cginc"
 
float4 _Vector1;
sampler2D _MainTex;
 
struct v2f {
    float4  pos : SV_POSITION;
    float2  uv : TEXCOORD0;
    float4 srcPos;
};
 
float4 _MainTex_ST;
 
v2f vert (appdata_base v)
{
    v2f o;
    o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
    o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
   	o.srcPos = v.vertex;
   
    return o;
}
 
half4 frag (v2f i) : COLOR
{
    half4 texcol = tex2D (_MainTex, i.uv);
    
    float d1 = dot(normalize(i.srcPos), normalize(_Vector1));
    
    if(d1 >= 0) {
    	texcol.a = 0;
    }
    
    return texcol;
}
ENDCG
 
    }
}
Fallback "VertexLit"
} 