import { registerPlugin } from '@capacitor/core';

export interface SharePreviewPlugin {
  share(options: {
    title: string;
    text?: string;
    url?: string;
  }): Promise<void>;
}

const SharePreview = registerPlugin<SharePreviewPlugin>('SharePreview', {
  web: () => import('./share-preview.web').then(m => new m.SharePreviewWeb()),
});

export { SharePreview };
