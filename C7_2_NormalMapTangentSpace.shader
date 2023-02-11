// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Learn/C7_2/Normal Map In Tangent Space" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)		//颜色
		_MainTex ("Main Tex", 2D) = "white" {}			//纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}			//法线纹理
		_BumpScale ("Bump Scale", Float) = 1.0			//凹凸程度
		_Specular ("Specular", Color) = (1, 1, 1, 1)	//高光颜色
		_Gloss ("Gloss", Range(8.0, 256)) = 20			//高光范围
	}
	SubShader {
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;		//顶点
				float3 normal : NORMAL;			//法线
				float4 tangent : TANGENT;		//切线
				float4 texcoord : TEXCOORD0;	//纹理
			};

			struct v2f {
				float4 pos : SV_POSITION;		//输出顶点
				float4 uv : TEXCOORD0;			//输出uv
				float3 lightDir: TEXCOORD1;		//光线方向
				float3 viewDir : TEXCOORD2;		//视线方向
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//uv的xy存储纹理 zw存储法线
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				//通过Unity内置宏获得rotation变换矩阵
				TANGENT_SPACE_ROTATION;

				// 转换光线方向和视角方向从世界空间到切线空间
				o.lightDir = mul(rotation, WorldSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, WorldSpaceViewDir(v.vertex)).xyz;


				return o;
			}

			//片元着色器采样得到空间法线方向，在再切线空间完成光照计算
			fixed4 frag(v2f i) : SV_Target
			{
				//获得切线空间中光线方向 和 视角方向
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//用tex2对法线纹理采样
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				//定义副切线
				fixed3 tangentNormal;
				// If the texture is not marked as "Normal map"
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// Or mark the texture as "Normal map", and use the built-in funciton
				tangentNormal = UnpackNormal(packedNormal);			//内置函数UnpackNormal()可以获得正确的法线方向
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
