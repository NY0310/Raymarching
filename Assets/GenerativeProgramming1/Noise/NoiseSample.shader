Shader "Hide/NoiseSample"
{
	Properties
	{
		[KeywordEnum(2D,3D)]
		_NoiseSpace ("Noise Space", int) = 0

		[KeywordEnum(Value, Perlin, Cellular, Curl, fbm, Random)]
		_NoiseType ("Noise Type", int) = 0

		_NoiseScale ("Noise Scale", Range(0,100)) = 10
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Assets/GenerativeProgramming1/Noise/Noise.cginc"
			// #include "Noise_test.cginc"
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 oPos : TEXCOORD1;
			};

			int _NoiseSpace;
			int _NoiseType;
			float _NoiseScale;

			float getNoiseFrom2D(float2 uv){
				float value = 0;
				float2 noisePos = uv * _NoiseScale;
				switch(_NoiseType){
					case 0:
						value = valNoise(noisePos);
						break;
					
					case 1:
						value = pNoise(noisePos);
						break;

					case 2:
						value = cNoise(noisePos);
						break;

					case 3:
						value = curlNoise(noisePos).r;
						break;

					case 4:
						value = fbm(noisePos);
						break;

					case 5:
						value = rand(noisePos);
						break;
				}
				return value;
			}

			float getNoiseFrom3D(float3 pos){
				float value = 0;
				float3 noisePos = pos * _NoiseScale;
				switch(_NoiseType){
					case 0:
						value = valNoise(noisePos);
						break;
					
					case 1:
						value = pNoise(noisePos);
						break;

					case 2:
						value = cNoise(noisePos);
						break;

					case 3:
						value = curlNoise(noisePos).r;
						break;

					case 4:
						value = fbm(noisePos);
						break;
					
					case 5:
						value = rand(noisePos);
						break;
				}
				return value;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.oPos = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = 1;
				if(_NoiseSpace == 0){

					col.rgb = getNoiseFrom2D(i.uv);

				} else if(_NoiseSpace == 1){

					col.rgb = getNoiseFrom3D(i.oPos);

				}
				
				return col;
			}
			ENDCG
		}
	}
}
