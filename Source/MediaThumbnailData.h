//*****************************************************************************
//
//	Copyright 2017 Microsoft Corporation
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//	http ://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//
//*****************************************************************************

#pragma once

namespace FFmpegInteropX
{
	
	using namespace Windows::Storage::Streams;

	public ref class MediaThumbnailData sealed
	{
		IBuffer^ _buffer;
		winrt::hstring _extension;

	public:

		property IBuffer^ Buffer
		{
			IBuffer^ get()
			{
				return _buffer;
			}
		}
		property winrt::hstring Extension
		{
			winrt::hstring get()
			{
				return _extension;
			}
		}

		MediaThumbnailData(IBuffer^ buffer, winrt::hstring extension)
		{
			this->_buffer = buffer;
			this->_extension = extension;
		}
	private: ~MediaThumbnailData()
		{
			delete _buffer;
			delete _extension;
		}
	};
}
