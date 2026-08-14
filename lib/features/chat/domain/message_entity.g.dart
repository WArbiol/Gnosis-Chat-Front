// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CitationEntityImpl _$$CitationEntityImplFromJson(Map<String, dynamic> json) =>
    _$CitationEntityImpl(
      pdfName: json['pdf_name'] as String,
      page: (json['page'] as num).toInt(),
      snippet: json['snippet'] as String? ?? '',
    );

Map<String, dynamic> _$$CitationEntityImplToJson(
  _$CitationEntityImpl instance,
) => <String, dynamic>{
  'pdf_name': instance.pdfName,
  'page': instance.page,
  'snippet': instance.snippet,
};
