Shader "Raymarching/SphereTracing/Sphere"
{
    Properties
    {
        [IntRange]_Iteration ("Marching Iteration", Range(0, 128)) = 0
        _Radius ("Radius", Range(0, 0.5)) = 0.3
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            uint _Iteration; //レイの行進の最大数
            float _Radius;   //描画する球の半径
            
            //球の距離関数
            float distFromSphere(float3 pos)
            {
                //引数の座標からオブジェクトの表面の距離
                return length(pos) - _Radius;
            }
            
            float3 getNormal(float3 pos)
            {
                float epsilon = 0.0001;
                float x = distFromSphere(pos + float3(epsilon, 0, 0)) - distFromSphere(pos - float3(epsilon, 0, 0));
                float y = distFromSphere(pos + float3(0, epsilon, 0)) - distFromSphere(pos - float3(0, epsilon, 0));
                float z = distFromSphere(pos + float3(0, 0, epsilon)) - distFromSphere(pos - float3(0, 0, epsilon));
                return normalize(float3(x, y, z));
            }
            
            struct appdata
            {
                float4 vertex: POSITION;
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
                float3 oPos: TEXCOORD0;
            };
            
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
                float3 cameraOPos = mul(unity_WorldToObject,
                float4(_WorldSpaceCameraPos, 1));
                
                //オブジェクト座標系でのカメラからピクセルの座標のレイ
                float3 rayDir = normalize(i.oPos - cameraOPos);
                //カメラ座標からレイをスタート
                float3 currentPos = cameraOPos;
                bool isCollided = false;
                for (uint j = 0; j < _Iteration; j ++)
                {
                    //オブジェクトの表面からの距離
                    float dist = distFromSphere(currentPos);
                    //オブジェクトに向かって表面までの距離分すすむ
                    currentPos += rayDir * dist;
                    //当たったらループ終了
                    isCollided = dist <= 0.000001;
                    if (isCollided) break;
                }
                
                fixed4 col = 1;
                if(isCollided)
                {
                    float3 normal = UnityObjectToWorldNormal(getNormal(currentPos));
                    float3 lightDir = UnityWorldSpaceLightDir(mul(unity_ObjectToWorld, float4(currentPos, 1)));
                    float NdotL = dot(normal, lightDir);
                    col.rgb = NdotL * 0.5f + 0.5f;
                }
                else
                {
                    discard;
                }
                
                return col;
            }
            ENDCG
            
        }
    }
}
