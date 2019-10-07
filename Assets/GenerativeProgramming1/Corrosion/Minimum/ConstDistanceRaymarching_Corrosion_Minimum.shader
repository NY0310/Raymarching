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

           uint _Iteration;
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
                float4 vertex: SV_POSITION;
                float3 oPos: TEXCOORD0
            };

            float getNoise(float3 pos);
            float getDepth(float3 oPos);
            float distFromSphere(float3 pos);
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.oPos = v.vertex.xyz;
                return o;
            }
                        
            fixed4 frag(v2f i): SV_Target
            {
                //カメラの位置（オブジェクト座標系）
                float3 cameraOpos = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                float3 rayDir = normalize(i.oPos - cameraOpos);
                float3 delta = rayDir * (1.0 / _Iteration);
                float3 currentPos = i.oPos;
                bool isCollided = false;
                for(uint j = 0; j < _Iteration; j ++)
                {
                     //レイが描画する球の外側なら次のループにスキップ
                    float dist = distFromSphere(currentPos);
                    if(dist > 0){
                        currentPos += delta;
                        continue;
                    }
                    float noiseValue = getNoise(currentPos);
                    isCollided = noiseValue > _Threshold;
                    if(isCollided) break;
                    currentPos += delta;
                }

                if(!isCollided) discard;
                fout o;
                UNITY_INITIALIZE_OUTPUT(fout,o);
                float3 collidedWpos = mul(unity_ObjectToWorld, float4(currentPos, 1));
                //隣接ピクセルで法線推定
                float3 ddxVec = normalize(ddx(collidedWpos));
                float3 ddyVec = normalize(ddy(collidedWpos));
                float3 lightDir = UnityWorldSpaceLightDir(collidedWpos);
                float NdotL = dot(normalize, lightDir);
                o.col.rgb = NdotL * 0.5 + 0.5;
                o.depth = getDepth(currentPos);
                return o;
            }

              float getNoise(float3 pos)
            {
                float value = 0;
                float3 noisePos = pos * _NoiseScale;
                if(_NoiseType == 0)
                {
                value = valNoise(noisePos);
                }
                else if(_NoiseType == 1)
                {
                value = pNoise(noisePos);
                }
                else if(_NoiseType == 2)
                {
                value = cNoise(noisePos);
                }
                else if(_NoiseType == 3)
                {
                value = curlNoise(noisePos).r * 0.5 + 0.5;
                }
                else if(_NoiseType == 4)
                {
                value = fbm(noisePos);
                }
                return value; 
            }

            float getDepth(float3 oPos)
            {
                float4 pos = UnityObjectToClipPos(float4(oPos, 1.0));
                //depthの算出方法はDirect3DとOpenGL系で違う。
                #if UNITY_UV_STARTS_AT_TOP
                    return pos.z / pos.w;
                #else 
                    return(pos.z / pos.w) * 0.5 + 0.5;
                #endif
            }

            //球の距離関数
            float distFromSphere(float3 pos)
            {
                return length(pos) - _Radius;
            }
            ENDCG
        }
    }
}
