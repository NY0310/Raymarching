Shader "Hidden/ConstDistanceRaymarching_Corrosion_Minimum"
{
    Properties
    {
        [Header(Raymarching)]
        [IntRange]_Iteration ("Marching Iteration", Range(0, 2048)) = 256
        _Radius ("Radius", Range(0, 0.5)) = 0.45
        
        [Header(Noise)]
        _Threshold ("Threshold", Range(0, 1)) = 0.5
        [KeywordEnum(Value, Perlin, Cellular, Curl, fbm)]
        _NoiseType ("Noise Type", int) = 0
        _NoiseScale ("Noise Scale", Range(0, 100)) = 10
    }
    SubShader
    {
        Tags {"RenderType"="Opaque" "LightMode"="ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
           #include "Assets/GenerativeProgramming1/Noise/Noise.cginc"

           unit _Iteration;
           float _Radius;

           float _Threshold;
           int _NoiseType;
           float _NoiseScale;
            
            struct appdata
            {
                float4 vertex: POSITION;
            };

            struct fout
            {
                fixed4 col: SV_Target;
                float depth: SV_Depth;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            
            sampler2D _MainTex;
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                col.rgb = 1 - col.rgb;
                return col;
            }
            ENDCG
            
        }
    }
}
