import io
import unittest

from PIL import Image

from tools.scan_browser.inference import decode_image, plausible, suppress


def box(x, y, w, h, confidence):
    return dict(left=x, top=y, width=w, height=h, confidence=confidence)


class FiltersTest(unittest.TestCase):
    def test_nested_duplicates_keep_strongest(self):
        strongest = box(450, 450, 40, 40, .9)
        self.assertEqual(suppress([box(451, 451, 20, 20, .6), strongest]), [strongest])

    def test_distinct_spots_are_preserved(self):
        boxes = [box(450, 450, 20, 20, .9), box(550, 550, 20, 20, .8)]
        self.assertEqual(suppress(boxes), boxes)

    def test_background_large_or_elongated_regions_are_rejected(self):
        self.assertFalse(plausible(box(0, 0, 20, 20, .9), 1000, 1000))
        self.assertFalse(plausible(box(400, 400, 300, 300, .9), 1000, 1000))
        self.assertFalse(plausible(box(450, 450, 100, 10, .9), 1000, 1000))
        self.assertTrue(plausible(box(450, 450, 20, 20, .9), 1000, 1000))

    def test_corrupt_and_small_images_fail_instead_of_zero_detections(self):
        with self.assertRaises(ValueError):
            decode_image(b'not-an-image')
        output = io.BytesIO()
        Image.new('RGB', (32, 32)).save(output, format='PNG')
        with self.assertRaises(ValueError):
            decode_image(output.getvalue())

    def test_exif_orientation_is_applied(self):
        output = io.BytesIO()
        image = Image.new('RGB', (300, 500))
        exif = Image.Exif()
        exif[274] = 6
        image.save(output, format='JPEG', exif=exif)
        self.assertEqual(decode_image(output.getvalue()).size, (500, 300))


if __name__ == '__main__':
    unittest.main()
