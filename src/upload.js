import { Upload } from 'https://esm.sh/tus-js-client@4.3.1'
import { supabase } from './lib/supabase.js'

export function uploadLargeVideo({ file, path, onProgress }) {
  return new Promise((resolve, reject) => {
    const projectUrl = import.meta.env.VITE_SUPABASE_URL
    const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
    const startedAt = performance.now()
    const upload = new Upload(file, {
      endpoint: `${projectUrl}/storage/v1/upload/resumable`,
      retryDelays: [0, 3000, 5000, 10000, 20000],
      chunkSize: 6 * 1024 * 1024,
      uploadSize: file.size,
      metadata: { bucketName: 'resource-files', objectName: path, contentType: file.type || 'video/mp4', cacheControl: '3600' },
      headers: { authorization: `Bearer ${key}`, apikey: key, 'x-upsert': 'false' },
      onError: reject,
      onProgress(bytesUploaded, bytesTotal) {
        const elapsed = Math.max((performance.now() - startedAt) / 1000, 0.1)
        const speed = bytesUploaded / elapsed
        const remaining = speed > 0 ? (bytesTotal - bytesUploaded) / speed : 0
        onProgress({ percent: Math.round((bytesUploaded / bytesTotal) * 100), bytesUploaded, bytesTotal, speed, remaining })
      },
      onSuccess: resolve,
    })
    upload.findPreviousUploads().then(previous => previous.length ? upload.resumeFromPreviousUpload(previous[0]).then(() => upload.start()) : upload.start()).catch(reject)
  })
}
