Shader "Hidden/Raymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
    }
    SubShader
    {
        // No culling or depth
        Cull Off
        Tags { "RenderType" = "Opaque" "DisableBatching" = "True" "Queue" = "Geometry+10" }
        
        CGINCLUDE
        #include "UnityCG.cginc"
        
        float sphere(float3 pos, float radius)
        {
            return length(pos) - radius;
        }
        
        float DistanceFunc(float3 pos)
        {
            return sphere(pos, 1.f);
        }
        
        float GetDepth(float3 pos)
        {
            float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos, 1.0));
            #if defined(SHADER_TARGET_GLSL)
                return(vpPos.z / vpPos.w) * 0.5 + 0.5;
            #else
                return vpPos.z / vpPos.w;
            #endif
        }
        
        float3 GetNormal(float3 pos)
        {
            const float d = 0.001;
            return 0.5 + 0.5 * normalize(float3(DistanceFunc(pos + float3(d, 0.0, 0.0)) - DistanceFunc(pos + float3(-d, 0.0, 0.0)), DistanceFunc(pos + float3(0.0, d, 0.0)) - DistanceFunc(pos + float3(0.0, -d, 0.0)), DistanceFunc(pos + float3(0.0, 0.0, d)) - DistanceFunc(pos + float3(0.0, 0.0, -d))));
        }
        
        ENDCG
        
        Pass
        {
            Tags { "LightMode" = "Deferred" }
            Stencil
            {
                Comp Always
                Pass Replace
                Ref 128
            }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile ___ UNITY_HDR_ON
            
            #include "UnityCG.cginc"
            
            struct VertInput
            {
                float4 vertex: POSITION;
            };
            
            struct VertOutput
            {
                float4 vertex: SV_POSITION;
                float4 screenPos: TEXCOORD0;
            };
            
            struct GBufferOut
            {
                half4 diffuse: SV_Target0; // rgb: diffuse,  a: occlusion
                half4 specular: SV_Target1; // rgb: specular, a: smoothness
                half4 normal: SV_Target2; // rgb: normal,   a: unused
                half4 emission: SV_Target3; // rgb: emission, a: unused
                float depth: SV_Depth;
            };
            
            VertOutput vert(VertInput v)
            {
                VertOutput o;
                o.vertex = v.vertex;
                o.screenPos = o.vertex;
                return o;
            }
            
            GBufferOut frag(VertOutput i)
            {
                float4 screenPos = i.screenPos;
                // アスペクト比に対応
                screenPos.x *= _ScreenParams.x / _ScreenParams.y;
                //ワールド座標系のカメラ座標
                float3 cameraPos = _WorldSpaceCameraPos;
                //z軸
                float3 camDir = -UNITY_MATRIX_V[2].xyz;
                //y軸
                float3 camUp = UNITY_MATRIX_V[1].xyz;
                //x軸
                float3 camSide = UNITY_MATRIX_V[0].xyz;
                //焦点距離(カメラからスクリーンまでの距離)
                float  focalLen = abs(UNITY_MATRIX_P[1][1]);
                //FarPlaneからNeaPlaneの距離
                float  maxDistance = _ProjectionParams.z - _ProjectionParams.y;
                //ピクセルからカメラ方向に対してのレイ
                float3 rayDir = normalize(camSide * screenPos.x + camUp * screenPos.y + camDir * focalLen);
                
                
                float distance = 0.0;
                float len = 0.0;
                //NearClipの位置からスタート
                float3 pos = cameraPos + _ProjectionParams.y * rayDir;
                for (int i = 0; i < 50; i ++)
                {
                    distance = DistanceFunc(pos);
                    len += distance;
                    pos += rayDir * distance;
                    if (distance < 0.001 || len > maxDistance) break;
                }

                if(distance > 0.001f)discard;
                
                float depth = GetDepth(pos);
                float3 normal = GetNormal(pos);
                
                GBufferOut o;
                o.diffuse = float4(1.0, 1.0, 1.0, 1.0);
                o.specular = float4(0.5, 0.5, 0.5, 1.0);
                o.emission = float4(0.0, 0.0, 0.0, 0.0);
                o.depth = depth;
                o.normal = float4(normal, 1.0);
                return o;
            }
            ENDCG
            
        }
    }
}