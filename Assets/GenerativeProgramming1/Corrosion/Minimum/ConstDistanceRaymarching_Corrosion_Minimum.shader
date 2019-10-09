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
        
        [Header(Lighting)]
        _InnerColor ("Inner Color", color) = (1, 0, 1, 1)
        _RimLightColor ("Rim Light Color", color) = (0, 1, 1, 1)
        _RimLightPower ("Rim Light Power", Range(0, 100)) = 20
        _SpecularPower ("Specular Power", Range(0, 100)) = 30
        
        [Header(Surface)]
        _SurfaceGradientWidth ("Surface Gradient Width", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
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
                float3 oPos: TEXCOORD0;
            };
            
            float getNoise(float3 pos);
            float getDepth(float3 oPos);
            float distFromSphere(float3 pos);
            float3 getDDCrossNormal(float3 wPos);
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.oPos = v.vertex.xyz;
                return o;
            }
            
            fout frag(v2f i)
            {
                //カメラの位置（オブジェクト座標系）
                float3 cameraOpos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //レイのベクトル(オブジェクト座標系)
                float3 rayDir = normalize(i.oPos - cameraOpos);
                //レイ方向に一回で進む
                float3 delta = rayDir * (1.0 / _Iteration);
                //ピクセルの位置からレイを飛ばすことで描画元メッシュ形状に応じた断面の描画を可能にしている
                float3 currentPos = i.oPos;
                bool isCollided = false;
                //レイが描画する球の内側に入った回数
                uint loopNumInSphere = 0;
                float noiseValue = 0;
                for (uint j = 0; j < _Iteration; j ++)
                {
                    float dist = distFromSphere(currentPos);
                    //レイが描画する球の外側なら次のループにスキップ
                    if (dist > 0)
                    {
                        //固定長レイマーチングなので定数でレイを進める
                        currentPos += delta;
                        continue;
                    }
                    //レイが描画する球の内側ならノイズによる凹みを見てレイを続けるか判定
                    loopNumInSphere++;
                    //ノイズによる凹みの深さを取得
                    float noiseValue = getNoise(currentPos);
                    //指定した深さより深い場合レイの更新を終了
                    isCollided = noiseValue > _Threshold;
                    if(isCollided) break;
                    //レイを更新
                    currentPos += delta;
                }
                
                if(!isCollided) discard;
                fout o;
                UNITY_INITIALIZE_OUTPUT(fout, o);
                float3 collidedWpos = mul(unity_ObjectToWorld, float4(currentPos, 1));
                //隣接ピクセルで法線推定
                float3 normal = getDDCrossNormal(collidedWPos);
                //ライトからオブジェクトへのベクトル
                float3 lightDir = UnityWorldSpaceLightDir(collidedWpos);
                //カメラからオブジェクトへのベクトル
                float3 viewDir = UnityWorldSpaceViewDir(collidedWpos);
                //ビューの反射ベクトル
                float3 reflectDir = normalize(reflect(-viewDir, normal));
                
                //法線とライトの内積
                float NdotL = dot(normal, lightDir);
                //反射ベクトルとライトの内積
                float RdotL = dot(reflectDir, lightDir);
                
                float3 reflectCol = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflectDir);
                float3 rimLightCol = pow(saturate(1 - NdotL), _SpecularPower)　 * _RimLightColor;
                float3 surfaceCol = pow(saturate(RdotL), _SpecularPower) * _LightColor0;
                
                //オブジェクトの球に沿った表面とそれ以外で処理を分岐
                bool isSurface = loopNumInSPhere == 1;
                if (isSurface)
                {
                    //スペキュラ、反射、リムライトを足して
                    float gradientWidth = (1.0 - _Threshold) * _SurfaceGradientWidth;
                    float k = smoothstep(1.0 - _Threshold) * _Threshold + gradientWidth,noizeValue);
                    float3 surfaceCol = specularCol + reflectCol + rimLightCol;
                    o.col.rgb = lerp(_InnerColor, surfaceCol + k);
                }
                else
                {
                    //中心から外に無けて黒→_InnerColorのグラデーション + リムライト
                    float dist = length(currentPos);
                    float3 gradientColor = _InnerColor * (dist / _Radius);
                    o.col.rab = gradientColor + rimLightCol;
                }
                o.col.rgb = NdotL * 0.5 + 0.5;
                o.depth = getDepth(currentPos);
                return o;
            }
            
            float3 getDDCrossNormal(float3 wPos)
            {
                float3 ddxVec = ddx(wPos);
                float3 ddyVec = ddy(wPos);
                return normalize(cross(ddyVec, ddxVec));
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
