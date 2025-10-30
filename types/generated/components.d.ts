import type { Schema, Struct } from '@strapi/strapi';

export interface ImagesSingleImage extends Struct.ComponentSchema {
  collectionName: 'components_images_single_images';
  info: {
    displayName: 'Single Image';
    icon: 'picture';
  };
  attributes: {
    Image: Schema.Attribute.Media<'images' | 'files' | 'videos' | 'audios'>;
  };
}

export interface TextText extends Struct.ComponentSchema {
  collectionName: 'components_text_texts';
  info: {
    displayName: 'Text';
    icon: 'file';
  };
  attributes: {
    Text: Schema.Attribute.Blocks;
  };
}

declare module '@strapi/strapi' {
  export module Public {
    export interface ComponentSchemas {
      'images.single-image': ImagesSingleImage;
      'text.text': TextText;
    }
  }
}
