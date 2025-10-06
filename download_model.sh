#!/bin/bash

# PackPal3 Model Download Script
# This script downloads the BERT model file from Apple's Core ML models

echo "🎒 PackPal3 - Downloading BERT Model..."
echo "This may take a few minutes due to the large file size"

# Create AI directory if it doesn't exist
mkdir -p PackPal3/AI/

# Download the model file from Apple's Core ML models
echo "Downloading BERT model from Apple Core ML..."
curl -L "https://ml-assets.apple.com/coreml/models/Text/QuestionAnswering/BERT_SQUAD/BERTSQUADFP16.mlmodel" -o PackPal3/AI/MobileBERT.mlmodel

# Check if download was successful
if [ -f "PackPal3/AI/MobileBERT.mlmodel" ]; then
    echo "✅ Model download complete!"
    echo "📁 File saved as: PackPal3/AI/MobileBERT.mlmodel"
    echo "🚀 You can now build and run the PackPal3 project in Xcode."
else
    echo "❌ Download failed. Please check your internet connection and try again."
    exit 1
fi
