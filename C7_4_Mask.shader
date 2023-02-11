// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Learn/C7_4/Mask Texture" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)			//颜色
		_MainTex ("Main Tex", 2D) = "white" {}				//贴图纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}				//法线纹理
		_BumpScale("Bump Scale", Float) = 1.0				//法线深度缩放值
		_SpecularMask ("Specular Mask", 2D) = "white" {}	//遮罩纹理
		_SpecularScale ("Specular Scale", Float) = 1.0		//遮罩程度缩放值
		_Specular ("Specular", Color) = (1, 1, 1, 1)		//高光颜色
		_Gloss ("Gloss", Range(8.0, 256)) = 20				//高光范围
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;		//
			sampler2D _BumpMap;
			float _BumpScale;
			sampler2D _SpecularMask;
			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;		//顶点
				float3 normal : NORMAL;			//法线
				float4 tangent : TANGENT;		//切线
				float4 texcoord : TEXCOORD0;	//第一组纹理坐标
			};

			struct v2f
			{
				float4 pos : SV_POSITION;		//输出顶点
				float2 uv : TEXCOORD0;			//输出uv
				float3 lightDir: TEXCOORD1;		//输出光照方向
				float3 viewDir : TEXCOORD2;		//输出视角方向
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//贴图->uv转换 先缩放后平移
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				//内置宏后获取rotation
				TANGENT_SPACE_ROTATION;
				//转换至切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//切线空间光照和视角方向归一化
			 	fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//UnpackNormal对纹理解码 tex2D(纹理，uv)纹理采样
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));	//由于法线都是单位矢量，tangentNormal.z可以由tangentNormal.xy计算得出

				//反射率=纹理采样颜色*基本色
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//自然光=Unity自然光*反射率
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射=Unity光照颜色*反射率*max(0,(n*l))
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//Blinn-Pong高光模型specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				//新矢量=v+l归一化
			 	fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			 	//这里是给予高光遮罩 获得遮罩值=遮罩纹理采样*遮罩深度
			 	fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
			 	//用高光遮罩计算高光 Blinn-Pong高光模型*高光遮罩
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;

				//(自然光+漫反射+高光，1.0);
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
