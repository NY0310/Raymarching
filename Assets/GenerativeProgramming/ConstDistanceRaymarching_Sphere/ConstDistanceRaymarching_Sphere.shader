Shader "Raymarching/ConstDistanceRaymarching/Sphere"
{
    Properties
    {
        [IntRange]_Iteration ("Marching Iteration", Range(0, 2048)) = 128
        _Radius ("Radius", Range(0, 0.5)) = 0.3
        _MarchingDistance ("Marching Distance", Range(0, 0.1)) = 0.01
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
            
            uint _Iteration; //レイの行進の最大数
            float _Radius;   //描画する球の半径
            float _MarchingDistance;
            
            //球の距離関数
            float distFromSphere(float3 pos)
            {
                return length(pos) - _Radius;
            }

            float getDepth(float3 oPos)
            {
                float4 pos = UnityWorldToClipPos(float4(oPos,1.0));
                #if UNITY_UV_STARTS_AT_TOP
                    return pos.z / pos.w;
                #else
                    return(pos.z/pos.w) * 0.5 + 0.5;
                #endif
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
            
            struct fout
            {
                fixed4 col: SV_TARGET;
                float depth: SV_Depth;
            };
            
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
                float3 cameraOPos = mul(unity_WorldToObject,
                float4(_WorldSpaceCameraPos, 1));
                float3 rayDir = normalize(i.oPos - cameraOPos);
                float3 currentPos = i.oPos;
                bool isCollided = false;
                for (uint j = 0; j < _Iteration; j ++)
                {
                    float dist = distFromSphere(currentPos);
                    isCollided = dist <= 0.000001;
                    if (isCollided) break;
                    currentPos += rayDir * _MarchingDistance;
                }
                
                fixed4 col = 1;
                if(!isCollided) discard;
                float3 collidedWPos = mul(unity_ObjectToWorld, float4(currentPos, 1));
                float3 ddxVec = normalize(ddx(collidedWPos));
                float3 ddyVec = normalize(ddy(collidedWPos));
                float3 normal = cross(ddyVec, ddxVec);
                float3 lightDir = UnityWorldSpaceLightDir(collidedWPos);
                float NdotL = dot(normal, lightDir);
                col.rgb = NdotL * 0.5 + 0.5;
                col.depth = getDepth(currentPos);
                return col;
            }
            ENDCG
            
        }
    }
}
